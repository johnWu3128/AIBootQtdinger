#!/bin/bash
# 修复 Podman Machine 中的 no_proxy 配置

cat > /tmp/fix_proxy.sh << 'INNEREOF'
#!/bin/bash
cat > /etc/profile.d/default-env.sh << 'EOF'
export no_proxy="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,<local>"
export NO_PROXY="localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,<local>"
EOF
INNEREOF

podman machine ssh -- "sudo bash /tmp/fix_proxy.sh"
podman machine ssh -- "cat /etc/profile.d/default-env.sh"
