from google.cloud import bigquery
import time

# BigQuery Configuration
BQ_CONFIG = {
    'ethereum': {
        'dataset': 'bigquery-public-data.crypto_ethereum',
        'tables': {
            'token_transfers': 'token_transfers'
        }
    }
}

# PYUSD Contract Address
PYUSD_CONTRACT = "0x6c3ea9036406852006290770BEdFcAbA0e23A0e8"

def test_bigquery_pyusd_usage(client):
    """ Fetches minimal data for PYUSD token to avoid exceeding BigQuery quota. """
    if not client:
        return {'success': False, 'message': "BigQuery client not initialized."}

    table_ref = f"`{BQ_CONFIG['ethereum']['dataset']}.{BQ_CONFIG['ethereum']['tables']['token_transfers']}`"

    test_query = f"""
    SELECT transaction_hash, from_address, to_address, value
    FROM {table_ref}
    WHERE token_address = "{PYUSD_CONTRACT}"
    ORDER BY block_number ASC
    LIMIT 1
    """

    try:
        # Perform Dry Run First
        job_config_dry = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
        dry_run_job = client.query(test_query, job_config=job_config_dry)

        bytes_processed = dry_run_job.total_bytes_processed or 0
        bytes_processed_mb = bytes_processed / (1024**2)

        print(f"[Info] Estimated bytes processed: {bytes_processed_mb:.2f} MB")

        if bytes_processed > (50 * 1024**2):  # 50MB limit
            return {'success': False, 'error': f"Query exceeds 50MB limit. Estimated: {bytes_processed_mb:.2f} MB"}

        # Execute Actual Query
        job_config_run = bigquery.QueryJobConfig(use_query_cache=True)
        query_job = client.query(test_query, job_config=job_config_run)
        results = list(query_job.result())

        if results:
            tx = results[0]
            return {
                'success': True,
                'transaction_hash': tx.transaction_hash,
                'from': tx.from_address,
                'to': tx.to_address,
                'value': tx.value
            }
        else:
            return {'success': False, 'message': "No PYUSD transfers found."}

    except Exception as e:
        return {'success': False, 'error': str(e)}

# Initialize BigQuery Client
bq_client = bigquery.Client()

# Run PYUSD Query
result = test_bigquery_pyusd_usage(bq_client)
print(result)
