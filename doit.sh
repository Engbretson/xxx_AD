ldd xxx | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' ./new

