# main.py - Flask service for BigQuery PYUSD data
from flask import Flask, jsonify
from google.cloud import bigquery
import os
import datetime

app = Flask(__name__)

# Initialize BigQuery client
client = bigquery.Client()

# PYUSD Contract address
PYUSD_CONTRACT_ADDRESS = "0x6c3ea9036406852006290770BEdFcAbA0e23A0e8"  # Replace with actual PYUSD address

@app.route('/pyusd/supply_history', methods=['GET'])
def get_supply_history():
    """
    Retrieves PYUSD supply history by analyzing token transfers
    """
    try:
        # BigQuery query to calculate supply over time from transfers
        query = f"""
        WITH daily_mints AS (
            SELECT 
                DATE(block_timestamp) AS date,
                SUM(CASE 
                    WHEN from_address = '0x0000000000000000000000000000000000000000' 
                    THEN CAST(value AS FLOAT64) / 1000000
                    ELSE 0 
                END) AS minted
            FROM `bigquery-public-data.crypto_ethereum.token_transfers`
            WHERE token_address = '{PYUSD_CONTRACT_ADDRESS}'
            GROUP BY date
        ),
        daily_burns AS (
            SELECT 
                DATE(block_timestamp) AS date,
                SUM(CASE 
                    WHEN to_address = '0x0000000000000000000000000000000000000000' 
                    THEN CAST(value AS FLOAT64) / 1000000
                    ELSE 0 
                END) AS burned
            FROM `bigquery-public-data.crypto_ethereum.token_transfers`
            WHERE token_address = '{PYUSD_CONTRACT_ADDRESS}'
            GROUP BY date
        ),
        daily_changes AS (
            SELECT
                COALESCE(m.date, b.date) AS date,
                COALESCE(m.minted, 0) AS daily_minted,
                COALESCE(b.burned, 0) AS daily_burned
            FROM daily_mints m
            FULL OUTER JOIN daily_burns b ON m.date = b.date
        ),
        running_supply AS (
            SELECT
                date,
                daily_minted,
                daily_burned,
                SUM(daily_minted - daily_burned) OVER (ORDER BY date) AS supply
            FROM daily_changes
            ORDER BY date
        )
        SELECT
            date,
            supply
        FROM running_supply
        WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
        ORDER BY date
        """
        
        # Run the query
        query_job = client.query(query)
        results = query_job.result()
        
        # Format results
        supply_history = []
        for row in results:
            supply_history.append({
                "timestamp": row.date.isoformat(),
                "supply": row.supply
            })
        
        return jsonify({
            "status": "success",
            "data": supply_history
        })
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/pyusd/minting_history', methods=['GET'])
def get_minting_history():
    """
    Retrieves PYUSD minting and burning events
    """
    try:
        # BigQuery query to get minting and burning events
        query = f"""
        WITH minting_events AS (
            SELECT
                block_timestamp AS timestamp,
                transaction_hash,
                from_address,
                to_address,
                CAST(value AS FLOAT64) / 1000000 AS amount,
                CASE 
                    WHEN from_address = '0x0000000000000000000000000000000000000000' THEN 'mint'
                    WHEN to_address = '0x0000000000000000000000000000000000000000' THEN 'burn'
                END AS type
            FROM `bigquery-public-data.crypto_ethereum.token_transfers`
            WHERE 
                token_address = '{PYUSD_CONTRACT_ADDRESS}'
                AND (from_address = '0x0000000000000000000000000000000000000000' OR to_address = '0x0000000000000000000000000000000000000000')
        ),
        totals AS (
            SELECT
                SUM(CASE WHEN type = 'mint' THEN amount ELSE 0 END) AS total_minted,
                SUM(CASE WHEN type = 'burn' THEN amount ELSE 0 END) AS total_burned
            FROM minting_events
        )
        SELECT * FROM minting_events
        ORDER BY timestamp DESC
        LIMIT 50
        """
        
        # Run the query for minting events
        query_job = client.query(query)
        results = query_job.result()
        
        # Format minting events
        events = []
        for row in results:
            events.append({
                "timestamp": row.timestamp.isoformat(),
                "transaction_hash": row.transaction_hash,
                "address": row.to_address if row.type == 'mint' else row.from_address,
                "amount": row.amount,
                "type": row.type
            })
        
        # Query for totals
        totals_query = f"""
        SELECT
            SUM(CASE 
                WHEN from_address = '0x0000000000000000000000000000000000000000'
                THEN CAST(value AS FLOAT64) / 1000000 
                ELSE 0 
            END) AS minted,
            SUM(CASE 
                WHEN to_address = '0x0000000000000000000000000000000000000000' 
                THEN CAST(value AS FLOAT64) / 1000000
                ELSE 0 
            END) AS burned
        FROM `bigquery-public-data.crypto_ethereum.token_transfers`
        WHERE token_address = '{PYUSD_CONTRACT_ADDRESS}'
        """
        
        totals_job = client.query(totals_query)
        totals_result = list(totals_job.result())[0]
        
        return jsonify({
            "status": "success",
            "data": events,
            "totals": {
                "minted": totals_result.minted,
                "burned": totals_result.burned
            }
        })
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    # Get port from environment variable or default to 8080
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)