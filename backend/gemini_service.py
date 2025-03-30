import google.generativeai as genai
from dotenv import load_dotenv
import os

load_dotenv()

# Configure the Gemini API
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
genai.configure(api_key=GOOGLE_API_KEY)

class GeminiService:
    def __init__(self):
        self.model = genai.GenerativeModel('gemini-pro')
        
    async def generate_response(self, prompt: str) -> str:
        """
        Generate a response using Gemini API
        """
        try:
            response = await self.model.generate_content_async(prompt)
            return response.text
        except Exception as e:
            return f"Error generating response: {str(e)}"
    
    async def analyze_text(self, text: str, analysis_type: str = "general") -> str:
        """
        Analyze text based on specified type (e.g., sentiment, summary, etc.)
        """
        prompts = {
            "general": "Please analyze the following text and provide insights: ",
            "sentiment": "Analyze the sentiment of the following text: ",
            "summary": "Please provide a concise summary of the following text: ",
            "keywords": "Extract key points and keywords from the following text: "
        }
        
        prompt = prompts.get(analysis_type, prompts["general"]) + text
        return await self.generate_response(prompt)
    
    async def generate_code_suggestion(self, code: str, language: str) -> str:
        """
        Generate code suggestions or improvements
        """
        prompt = f"Please analyze this {language} code and suggest improvements: \n\n{code}"
        return await self.generate_response(prompt) 