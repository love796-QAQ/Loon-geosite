#!/bin/bash

# 克隆整个仓库
repo_url="https://github.com/SagerNet/sing-geosite.git"
download_dir="$HOME/Downloads/sing-geosite"

# 克隆指定分支
git clone --branch rule-set "$repo_url" "$download_dir"

# 切换到下载目录
cd "$download_dir" || exit

# 找到所有 .srs 文件
srs_files=$(find . -name "*.srs")

# 循环处理所有 .srs 文件
for srs_file in $srs_files; do
    echo "Processing $srs_file..."

    # 使用 sing-box 进行转换
    temp_output_file="temp_output.json"
    sing-box rule-set decompile --output "$temp_output_file" "$srs_file"

    # 检查生成的 JSON 内容
    cat "$temp_output_file"  # 输出内容以调试

    # 获取原文件名（不带后缀）
    filename="${srs_file%.srs}"
    final_output_file="${filename}.txt"

    # 格式化输出并保存到最终文件
    jq -r '
      .rules[] | 
      (.domain_suffix // empty | if type == "array" then .[] | "DOMAIN-SUFFIX, \(.)" else "DOMAIN-SUFFIX, \(.)" end) // empty,
      (.domain // empty | if type == "array" then .[] | "DOMAIN, \(.)" else "DOMAIN, \(.)" end) // empty
    ' "$temp_output_file" > "$final_output_file"

    # 输出生成的 txt 文件内容
    echo "Generated $final_output_file:"
    cat "$final_output_file"

    # 清理临时文件
    rm "$temp_output_file"
    rm "$local_srs_file"  # 删除本地下载的 .srs 文件

    # 切换到 rule-set 分支
    git checkout rule-set

    # 设置 Git 用户身份
    git config user.name "love796-QAQ"
    git config user.email "wangshuo523@outlook.com"

    # 添加最终输出文件到 Git
    git add "$final_output_file"

    # 提交更改
    git commit -m "Update $final_output_file with domains and suffixes"
done

# 删除除 .txt 文件外的所有文件
find . -type f ! -name "*.txt" -exec rm -f {} +

# 删除空文件夹
find . -type d -empty -exec rmdir {} +

# 推送更改
git push origin rule-set
