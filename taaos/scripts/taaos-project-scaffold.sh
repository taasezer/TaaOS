#!/bin/bash
#
# TaaOS Project Scaffolder
# Quick project setup for various frameworks
#

show_menu() {
    clear
    echo "========================================="
    echo "   TaaOS Project Scaffolder"
    echo "========================================="
    echo ""
    echo "Web Frameworks:"
    echo "  1. Next.js (React)"
    echo "  2. Vite + React"
    echo "  3. Vue 3"
    echo "  4. SvelteKit"
    echo "  5. Astro"
    echo ""
    echo "Backend:"
    echo "  6. Express.js"
    echo "  7. FastAPI (Python)"
    echo "  8. Actix-web (Rust)"
    echo "  9. Gin (Go)"
    echo ""
    echo "Desktop:"
    echo "  10. Tauri"
    echo "  11. Electron"
    echo ""
    echo "Mobile:"
    echo "  12. React Native"
    echo "  13. Flutter"
    echo ""
    echo "0. Exit"
    echo ""
    read -p "Select project type: " choice
}

create_nextjs() {
    read -p "Project name: " name
    npx create-next-app@latest "$name" --typescript --tailwind --app --use-npm
    cd "$name" || exit
    echo "Next.js project created: $name"
}

create_vite_react() {
    read -p "Project name: " name
    npm create vite@latest "$name" -- --template react-ts
    cd "$name" || exit
    npm install
    echo "Vite + React project created: $name"
}

create_vue() {
    read -p "Project name: " name
    npm create vue@latest "$name"
    echo "Vue 3 project created: $name"
}

create_sveltekit() {
    read -p "Project name: " name
    npm create svelte@latest "$name"
    echo "SvelteKit project created: $name"
}

create_astro() {
    read -p "Project name: " name
    npm create astro@latest "$name"
    echo "Astro project created: $name"
}

create_express() {
    read -p "Project name: " name
    mkdir -p "$name"
    cd "$name" || exit
    npm init -y
    npm install express cors dotenv
    npm install --save-dev typescript @types/node @types/express ts-node nodemon
    
    # Create basic structure
    mkdir -p src
    cat > src/index.ts <<EOF
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'TaaOS Express API' });
});

app.listen(PORT, () => {
    console.log(\`Server running on port \${PORT}\`);
});
EOF
    
    cat > tsconfig.json <<EOF
{
    "compilerOptions": {
        "target": "ES2020",
        "module": "commonjs",
        "outDir": "./dist",
        "rootDir": "./src",
        "strict": true,
        "esModuleInterop": true
    }
}
EOF
    
    echo "Express.js project created: $name"
}

create_fastapi() {
    read -p "Project name: " name
    mkdir -p "$name"
    cd "$name" || exit
    
    python3 -m venv venv
    source venv/bin/activate
    pip install fastapi uvicorn python-dotenv
    
    mkdir -p app
    cat > app/main.py <<EOF
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="TaaOS FastAPI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "TaaOS FastAPI"}
EOF
    
    cat > requirements.txt <<EOF
fastapi
uvicorn[standard]
python-dotenv
EOF
    
    echo "FastAPI project created: $name"
}

create_actix() {
    read -p "Project name: " name
    cargo new "$name"
    cd "$name" || exit
    
    cat >> Cargo.toml <<EOF

[dependencies]
actix-web = "4"
actix-cors = "0.7"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
EOF
    
    cat > src/main.rs <<EOF
use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use actix_cors::Cors;

async fn index() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "message": "TaaOS Actix-web API"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        let cors = Cors::permissive();
        App::new()
            .wrap(cors)
            .route("/", web::get().to(index))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
EOF
    
    echo "Actix-web project created: $name"
}

create_tauri() {
    read -p "Project name: " name
    npm create tauri-app@latest "$name"
    echo "Tauri project created: $name"
}

create_electron() {
    read -p "Project name: " name
    mkdir -p "$name"
    cd "$name" || exit
    npm init -y
    npm install electron
    echo "Electron project created: $name"
}

create_react_native() {
    read -p "Project name: " name
    npx react-native@latest init "$name"
    echo "React Native project created: $name"
}

create_flutter() {
    read -p "Project name: " name
    flutter create "$name"
    echo "Flutter project created: $name"
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1) create_nextjs ;;
        2) create_vite_react ;;
        3) create_vue ;;
        4) create_sveltekit ;;
        5) create_astro ;;
        6) create_express ;;
        7) create_fastapi ;;
        8) create_actix ;;
        9) echo "Gin scaffolding coming soon" ;;
        10) create_tauri ;;
        11) create_electron ;;
        12) create_react_native ;;
        13) create_flutter ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
