chmod u=rwx,g=rx,o=r "$(pwd)/run.sh"
chmod u=rwx,g=rx,o=r "$(pwd)/auth.sh"  
for f in $(ls -1 *.sh); do
  chmod u=rwx,g=rx,o=r "$f"
done