url=$1
curl -i "$url"
if which xdg-open > /dev/null; then
  xdg-open $url
elif which gnome-open > /dev/null; then
  gnome-open $url
elif which python > /dev/null; then
  python -m webbrowser $url
fi
    