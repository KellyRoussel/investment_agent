# Streamlit UI

This is a small Streamlit app to explore a user's investments and portfolio metrics.

Run locally (from the repository root):

```powershell
pip install -r requirements.txt
streamlit run app/ui/streamlit_app.py
```

Enter a user UUID when prompted. The app uses the same database configured by `DATABASE_URL` in the environment or the default in `app/database.py`.
