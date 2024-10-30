#!/bin/bash

# 设置变量
base_url="https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set"

# 循环处理所有 .srs 文件
srs_files=$(curl -s https://api.github.com/repos/SagerNet/sing-geosite/contents/rule-set | jq -r '.[].name' | grep '\.srs$')

if [ -z "$srs_files" ]; then
    echo "No .srs files found."
    exit 1
fi

for srs_file in $srs_files; do
    echo "Processing $srs_file..."

    # 下载 .srs 文件
    full_url="$base_url/$srs_file"
    local_srs_file="$HOME/Downloads/$srs_file"  # 本地保存路径
    curl -L -o "$local_srs_file" "$full_url"  # 下载到本地

    # 使用 sing-box 进行转换
    temp_output_file="temp_output.json"
    sing-box rule-set decompile --output "$temp_output_file" "$local_srs_file"

    # 获取原文件名（不带后缀）
    filename="${srs_file%.srs}"
    final_output_file="${filename}.txt"

    # 格式化输出并保存到最终文件
    jq -r '.rules[] | .domain[] | "DOMAIN, \(. )" 
          , .rules[] | .domain_suffix[] | "DOMAIN-SUFFIX, \(. )"' "$temp_output_file" > "$final_output_file"

    # 清理临时文件
    rm "$temp_output_file"
    rm "$local_srs_file"  # 删除本地下载的 .srs 文件

    # 切换到 rule-set 分支
    git checkout rule-set

    # 添加最终输出文件到 Git
    git add "$final_output_file"

    # 提交更改
    git commit -m "Update $final_output_file with domains and suffixes"
done

# 推送更改
git push origin rule-set
