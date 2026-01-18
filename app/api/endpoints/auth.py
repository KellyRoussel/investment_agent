"""
Authentication endpoints for user registration, login, and token management.
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import RiskTolerance
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, RefreshRequest
from app.schemas.user import UserResponse
from app.utils.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_token,
    get_current_user,
)


router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    """
    Register a new user.

    Creates a new user account with the provided details and returns
    access and refresh tokens.

    Args:
        request: Registration request with email, password, and user details
        db: Database session

    Returns:
        TokenResponse with access_token, refresh_token, and expiration info

    Raises:
        HTTPException 409: If email already exists
    """
    user_repo = UserRepository(db)

    # Check if email already exists
    existing_user = user_repo.get_by_email(request.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    # Hash password
    password_hash = hash_password(request.password)

    # Parse risk tolerance if provided
    risk_tolerance = RiskTolerance.MODERATE
    if request.risk_tolerance:
        try:
            risk_tolerance = RiskTolerance(request.risk_tolerance.lower())
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid risk tolerance. Must be one of: {', '.join([r.value for r in RiskTolerance])}",
            )

    # Create user
    user = user_repo.create(
        email=request.email,
        password_hash=password_hash,
        full_name=request.full_name,
        currency_preference=request.currency_preference,
        risk_tolerance=risk_tolerance,
    )

    # Generate tokens
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/login", response_model=TokenResponse)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    """
    Authenticate user and generate tokens.

    Validates user credentials and returns access and refresh tokens.

    Args:
        request: Login request with email and password
        db: Database session

    Returns:
        TokenResponse with access_token, refresh_token, and expiration info

    Raises:
        HTTPException 401: If credentials are invalid
    """
    user_repo = UserRepository(db)

    # Get user by email
    user = user_repo.get_by_email(request.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if account is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive",
        )

    # Update last login
    user.last_login = datetime.utcnow()
    user_repo.update(user)

    # Generate tokens
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(
    request: RefreshRequest,
    db: Session = Depends(get_db),
):
    """
    Refresh access token using refresh token.

    Validates the refresh token and generates a new access token.

    Args:
        request: Refresh request with refresh_token
        db: Database session

    Returns:
        TokenResponse with new access_token and same refresh_token

    Raises:
        HTTPException 401: If refresh token is invalid
    """
    # Verify refresh token
    payload = verify_token(request.refresh_token, token_type="refresh")

    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify user still exists and is active
    user_repo = UserRepository(db)
    user = user_repo.get_by_id(user_id)

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Generate new access token
    access_token = create_access_token(data={"sub": str(user.id)})

    return TokenResponse(
        access_token=access_token,
        refresh_token=request.refresh_token,  # Return same refresh token
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.get("/me", response_model=UserResponse)
def get_me(
    current_user = Depends(get_current_user),
):
    """
    Get current authenticated user.

    Returns the profile of the currently authenticated user.

    Args:
        current_user: Current user from JWT token (dependency)

    Returns:
        UserResponse with user details
    """
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        currency_preference=current_user.currency_preference,
        risk_tolerance=current_user.risk_tolerance,
        is_active=current_user.is_active,
        email_verified=current_user.email_verified,
        last_login=current_user.last_login,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
    )
