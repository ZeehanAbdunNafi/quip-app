# Quip App Upload Guide for School Web Server

## 🚀 How to Upload Your Quip App to School's public_html

### Step 1: Build the Web App
```bash
flutter build web --release
```

### Step 2: Prepare Files for Upload
The files you need to upload are in the `build/web` folder:
- `index.html`
- `flutter.js`
- `flutter_bootstrap.js`
- `canvaskit/` folder
- All other files in `build/web/`

### Step 3: Upload to School Server

#### Option A: Using MobaXterm File Transfer
1. Open MobaXterm and connect to your school's server
2. Navigate to your `public_html` directory
3. Upload all files from `build/web/` to `public_html/`

#### Option B: Using FTP/SFTP
```bash
# Using command line FTP
ftp your-school-server.com
cd public_html
put build/web/*

# Or using SFTP
sftp username@your-school-server.com
cd public_html
put -r build/web/*
```

#### Option C: Using File Manager
1. Connect to your school's web server
2. Navigate to `public_html` folder
3. Upload all contents of `build/web/` folder

### Step 4: Access Your App
Your app will be available at:
```
http://your-school-domain.com/~your-username/
```

### 🔧 Important Notes

#### File Permissions
Make sure files have correct permissions:
```bash
chmod 644 *.html *.js *.css
chmod 755 canvaskit/
```

#### .htaccess (if needed)
If your school uses Apache, create `.htaccess` in `public_html`:
```apache
# Enable CORS for web app
Header always set Access-Control-Allow-Origin "*"
Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type"

# Handle Flutter routing
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /index.html [QSA,L]
```

#### Update Process
To update your app:
1. Make changes to your Flutter code
2. Run `flutter build web --release`
3. Upload the new `build/web/` files to `public_html/`
4. Replace old files with new ones

### 📱 Mobile Access
- Works on all devices via the web URL
- Responsive design adapts to screen size
- No special setup needed

### 🐛 Troubleshooting

#### App Not Loading
- Check if all files were uploaded correctly
- Verify `index.html` is in the root of `public_html`
- Check browser console for errors
- Ensure file permissions are correct

#### Routing Issues
- Flutter web apps need server-side routing support
- Add `.htaccess` file if using Apache
- Contact school IT if using different server

#### Performance Issues
- School servers might be slower than local
- Consider optimizing images and assets
- Check with school IT about bandwidth limits

### 📞 School-Specific Setup

#### Check Your School's Setup
1. **Domain**: What's your school's web domain?
2. **Username**: What's your school account username?
3. **Server Type**: Apache, Nginx, or other?
4. **File Limits**: Any size restrictions?

#### Common School URLs
```
http://school.edu/~username/
http://web.school.edu/~username/
http://students.school.edu/~username/
```

### 🔄 Quick Update Script
Create a simple script to automate updates:

```bash
#!/bin/bash
# update_quip.sh
echo "Building Flutter web app..."
flutter build web --release

echo "Uploading to school server..."
scp -r build/web/* username@school-server.com:public_html/

echo "Update complete!"
echo "Visit: http://school.edu/~username/"
```

### 📋 Checklist Before Upload
- [ ] Flutter web build completed successfully
- [ ] All files present in `build/web/`
- [ ] School server credentials ready
- [ ] `public_html` directory accessible
- [ ] File permissions set correctly
- [ ] `.htaccess` file created (if needed)

### 🎯 Final URL Format
Your app will be accessible at:
```
http://[SCHOOL_DOMAIN]/~[YOUR_USERNAME]/
```

Example:
```
http://web.myschool.edu/~john.doe/
``` 