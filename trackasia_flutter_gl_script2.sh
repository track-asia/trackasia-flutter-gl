#!/bin/bash

rename_java_packages() {
    echo "🔍 Đang tìm tất cả thư mục có đường dẫn org/trackasia..."

    # Tìm tất cả thư mục org/trackasia trong dự án
    FOLDERS=$(find . -type d -path "*/org/trackasia")

    if [ -z "$FOLDERS" ]; then
        echo "⚠️ Không tìm thấy thư mục org/trackasia nào!"
        exit 1
    fi

    for FOLDER in $FOLDERS; do
        NEW_FOLDER=$(echo "$FOLDER" | sed 's|/org/trackasia|/com/trackasia|g')
        
        echo "📂 Đổi $FOLDER → $NEW_FOLDER"

        # Tạo thư mục mới nếu chưa có
        mkdir -p "$NEW_FOLDER"

        # Di chuyển toàn bộ file từ org/trackasia sang com/trackasia
        mv "$FOLDER"/* "$NEW_FOLDER/"

        # Kiểm tra nếu thư mục cũ rỗng thì xóa
        if [ -z "$(ls -A "$FOLDER")" ]; then
            echo "🗑 Xóa thư mục rỗng: $FOLDER"
            rm -rf "$FOLDER"
        fi
    done

    echo "✅ Hoàn thành đổi tên thư mục!"

    echo "🔄 Đang thay thế com.trackasia → com.trackasia trong tất cả file..."

    # Danh sách đuôi file cần thay thế nội dung
    FILE_TYPES=("java" "kt" "xml" "gradle" "properties" "json")

    for EXT in "${FILE_TYPES[@]}"; do
        find . -type f -name "*.${EXT}" -exec sed -i '' 's/org\.trackasia/com.trackasia/g' {} \;
    done

    echo "✅ Hoàn thành thay thế nội dung trong tất cả file!"
}

main() {
    echo "TrackAsia Select an option:" 
    options=("Rename Java/Kotlin Packages (org/trackasia -> com/trackasia)" "Exit")
    
    select opt in "${options[@]}"; do
        case $opt in
            "Rename Java/Kotlin Packages (org/trackasia -> com/trackasia)")
                rename_java_packages
                ;;
            "Exit")
                echo "Complete"
                exit 0
                ;;
            *) echo "Invalid option";;
        esac
    done
}

main
