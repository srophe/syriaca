#!/busybox/sh

server_startup () {
    java org.exist.start.Main jetty | tee startup.log
}

password_change() {
    while true; do
        tail -n 20 startup.log | grep "Jetty server started" && break
        sleep 5
    done

    echo "running password change"
    java org.exist.start.Main client \
    --no-gui \
    -u admin -P '' \
    -x "sm:passwd('admin', '$ADMIN_PASSWORD')" 
    echo "ran password change"
}

server_startup &
password_change
wait
