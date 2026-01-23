import os
import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.endpoints.auth import router as auth_router
from app.api.endpoints.investments import router as investments_router
from app.api.endpoints.portfolio import router as portfolio_router
from app.api.endpoints.users import router as users_router

app = FastAPI(title="Investment Agent API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Vite default port
        "http://localhost:3000",  # Alternative React port
        "http://127.0.0.1:5173",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(investments_router, tags=["Investments"])
app.include_router(portfolio_router, tags=["Portfolio"])
app.include_router(users_router, tags=["Users"])

