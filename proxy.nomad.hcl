job "nginx-proxy" {

  group "nginx" {
    network {
      port "http" {
        static = 80
        to     = 8080
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image          = "nginx:mainline"
        command        = "nginx"
        args           = ["-c", "/local/nginx.conf"]
        ports          = ["http"]
        auth_soft_fail = true
      }

      identity {
        env  = true
      }

      resources {
        cpu    = 200
        memory = 200
      }

      template {
        destination = "local/nginx.conf"
        data        = <<EOF
daemon off;

events {}

http {
  server {
    listen 8080;

    location /.well-known/jwks.json {
      proxy_pass http://unix:/secrets/api.sock:$request_uri;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

      # Public endpoint so set auth token
      proxy_set_header Authorization "Bearer {{ env "NOMAD_TOKEN" }}";
    }

    location /.well-known/openid-configuration {
      proxy_pass http://unix:/secrets/api.sock:$request_uri;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

      # Public endpoint so set auth token
      proxy_set_header Authorization "Bearer {{ env "NOMAD_TOKEN" }}";
    }

    location /ui {
      proxy_pass http://unix:/secrets/api.sock:$request_uri;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

      # Public endpoint so set auth token
      proxy_set_header Authorization "Bearer {{ env "NOMAD_TOKEN" }}";
    }

    location / {
      proxy_pass http://unix:/secrets/api.sock:$request_uri;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

      proxy_buffering off;

      # The Upgrade and Connection headers are used to establish
      # a WebSockets connection.
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";

      # The default Origin header will be the proxy address, which
      # will be rejected by Nomad. It must be rewritten to be the
      # host address instead.
      proxy_set_header Origin "${scheme}://${proxy_host}";
    }
  }
}
EOF
      }
    } # task
  }   # group
}     # job
