"""
Repository for User database operations.
"""
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.user import User, RiskTolerance


class UserRepository:
    """Repository for User CRUD operations."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, email: str, password_hash: str, full_name: str, 
               currency_preference: str = "USD", 
               risk_tolerance: RiskTolerance = RiskTolerance.MODERATE) -> User:
        """
        Create a new user.
        
        Args:
            email: User's email
            password_hash: Hashed password
            full_name: User's full name
            currency_preference: Preferred currency
            risk_tolerance: Risk tolerance level
            
        Returns:
            Created User instance
        """
        user = User(
            email=email,
            password_hash=password_hash,
            full_name=full_name,
            currency_preference=currency_preference,
            risk_tolerance=risk_tolerance
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def get_by_id(self, user_id: UUID) -> Optional[User]:
        """
        Get user by ID.
        
        Args:
            user_id: User UUID
            
        Returns:
            User instance or None if not found
        """
        return self.db.query(User).filter(User.id == user_id).first()
    
    def get_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email.
        
        Args:
            email: User's email
            
        Returns:
            User instance or None if not found
        """
        return self.db.query(User).filter(User.email == email).first()
    
    def get_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        """
        Get all users with pagination.
        
        Args:
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of User instances
        """
        return self.db.query(User).offset(skip).limit(limit).all()
    
    def update(self, user: User) -> User:
        """
        Update user.
        
        Args:
            user: User instance with updated data
            
        Returns:
            Updated User instance
        """
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def delete(self, user_id: UUID) -> bool:
        """
        Delete user by ID.
        
        Args:
            user_id: User UUID
            
        Returns:
            True if deleted, False if not found
        """
        user = self.get_by_id(user_id)
        if user:
            self.db.delete(user)
            self.db.commit()
            return True
        return False

