#!/bin/bash
# 修复Podman Machine中的no_proxy配置

# 备份原始文件
sudo cp /etc/profile.d/default-env.sh /etc/profile.d/default-env.sh.bak 2>/dev/null || true

# 创建修复后的no_proxy（使用逗号分隔而不是分号）
cat > /tmp/fix_no_proxy.sh << 'EOF'
#!/bin/bash
# 修复no_proxy，将分号替换为逗号
sed -i 's/;/,/g' /etc/profile.d/default-env.sh

# 确保格式正确
echo "Fixed no_proxy format"
EOF

chmod +x /tmp/fix_no_proxy.sh
sudo bash /tmp/fix_no_proxy.sh

echo "=== 修复完成 ==="
echo "修复后的内容:"
cat /etc/profile.d/default-env.sh
