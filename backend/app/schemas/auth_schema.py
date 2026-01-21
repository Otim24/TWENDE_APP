
from pydantic import BaseModel
from typing import Optional
from app.models.user_model import UserRole

class UserCreate(BaseModel):
    phone: str
    password: str
    full_name: str
    role: UserRole = UserRole.PASSENGER

class Token(BaseModel):
    access_token: str
    token_type: str
