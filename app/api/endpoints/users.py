from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.repositories import UserRepository
from app.schemas.user import UserCreate, UserListResponse, UserResponse, UserUpdate

router = APIRouter()


@router.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
) -> UserResponse:
    user_repo = UserRepository(db)
    existing = user_repo.get_by_email(payload.email)
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered.",
        )

    user = user_repo.create(
        email=payload.email,
        password_hash=payload.password_hash,
        full_name=payload.full_name,
        currency_preference=payload.currency_preference,
        risk_tolerance=payload.risk_tolerance,
    )
    return UserResponse.model_validate(user)


@router.patch("/users/{user_id}", response_model=UserResponse)
def update_user(
    user_id: UUID,
    payload: UserUpdate,
    db: Session = Depends(get_db),
) -> UserResponse:
    user_repo = UserRepository(db)
    user = user_repo.get_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    if payload.email is not None:
        existing = user_repo.get_by_email(payload.email)
        if existing is not None and existing.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered.",
            )
        user.email = payload.email

    if payload.password_hash is not None:
        user.password_hash = payload.password_hash
    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.currency_preference is not None:
        user.currency_preference = payload.currency_preference
    if payload.risk_tolerance is not None:
        user.risk_tolerance = payload.risk_tolerance
    if payload.is_active is not None:
        user.is_active = payload.is_active

    user_repo.update(user)
    return UserResponse.model_validate(user)


@router.get("/users", response_model=UserListResponse)
def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
) -> UserListResponse:
    user_repo = UserRepository(db)
    users = user_repo.get_all(skip=skip, limit=limit)
    total = db.query(User).count()
    return UserListResponse(items=users, total=total, limit=limit, offset=skip)
