# Quip App Deployment Guide

## 🚀 How to Host Your Quip App on School Computer

### Prerequisites
- Python 3.6+ installed on the school computer
- MobaXterm or similar SSH client
- Flutter web build files

### Step 1: Build the Web App
```bash
flutter build web --release
```

### Step 2: Transfer Files to School Computer
1. Copy the entire project folder to your school computer
2. Or copy just the `build/web` folder and the server files

### Step 3: Start the Server

#### Option A: Using Python (Recommended)
```bash
python server.py
```

#### Option B: Using the Batch File (Windows)
```bash
start_server.bat
```

#### Option C: Manual Python Server
```bash
cd build/web
python -m http.server 8080
```

### Step 4: Access Your App
- **Local**: http://localhost:8080
- **Network**: http://[SCHOOL_COMPUTER_IP]:8080

### Step 5: Make it Accessible to Others
1. Find your school computer's IP address:
   ```bash
   ipconfig  # Windows
   ifconfig  # Linux/Mac
   ```

2. Share the URL with classmates:
   ```
   http://[SCHOOL_IP]:8080
   ```

### 🔧 Configuration Options

#### Change Port (if 8080 is blocked)
Edit `server.py` and change:
```python
PORT = 8080  # Change to 3000, 5000, etc.
```

#### Run in Background (Linux/Mac)
```bash
nohup python server.py > server.log 2>&1 &
```

#### Windows Service (Advanced)
Use tools like NSSM to run as a Windows service.

### 🛡️ Security Notes
- This is a simple HTTP server for development/demo
- For production, use proper web servers (Apache, Nginx)
- Consider HTTPS for sensitive data
- Check school's network policies

### 📱 Mobile Access
- Works on phones/tablets via the network URL
- Responsive design adapts to different screen sizes
- Test on different devices

### 🔄 Updates
To update the app:
1. Make changes to your Flutter code
2. Run `flutter build web --release` again
3. Copy the new `build/web` files to the server
4. Restart the server

### 🐛 Troubleshooting

#### Port Already in Use
```bash
# Find what's using the port
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Kill the process or change port
```

#### Can't Access from Other Computers
- Check Windows Firewall settings
- Ensure the port is open
- Try a different port (3000, 5000, etc.)

#### App Not Loading
- Check browser console for errors
- Ensure all files are in `build/web` directory
- Try clearing browser cache

### 📞 Support
If you encounter issues:
1. Check the server console for error messages
2. Verify Python is installed: `python --version`
3. Ensure all files are present in the correct locations 