@echo off
cd /d C:\Tools\workarea\test_feature\fl_mini_app_v3
call flutter build web --release
git add .
git commit -m "v16: GUARANTEED MainScreen, fix Location.fromJson"
git push origin main
echo DONE
pause

