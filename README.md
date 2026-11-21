# AuraFreq

Bộ phát âm đơn cho macOS, viết bằng SwiftUI và AVAudioEngine. Xoay mặt đĩa để dò âm, bấm vào số Hz để nhập chính xác hoặc chọn một trong mười preset. Âm thanh được tổng hợp ngay trên máy.

## Chọn tần số để nghe

Hz cho biết số dao động mỗi giây. Trong bảng dưới, “trầm”, “cao” mô tả cao độ tương đối giữa các preset. Chọn âm theo sở thích và thử ở âm lượng thấp.

| Preset | Có thể dùng để làm gì? |
|---|---|
| 174, 285 Hz | Thử hai âm trầm nhất trong danh sách nếu bạn thích âm nền thấp. |
| 396, 417, 432 Hz | So sánh các cao độ gần nhau. 432 Hz là điểm bắt đầu mặc định của ứng dụng. |
| 528, 639 Hz | Thử âm sáng, cao hơn và so sánh với 432 Hz ở mức nghe dễ chịu. |
| 741, 852, 963 Hz | Nhận biết sự khác biệt ở đầu cao của danh sách. Giảm âm lượng hoặc dừng nếu thấy chói. |

**Khi làm việc hoặc thư giãn**, bạn có thể chọn âm dễ chịu rồi đặt hẹn giờ. Chưa có cơ sở từ các nguồn dưới đây để khuyên một preset cụ thể nhằm tăng tập trung, chữa đau đầu, “chữa lành” hay giảm dopamine. Nghiên cứu về chú ý với nhịp binaural 40 Hz sử dụng hai tín hiệu khác nhau cho hai tai. AuraFreq phát sóng sin mono, nên nhập 40 Hz sẽ tạo một âm trầm đơn. [Nghiên cứu thực nghiệm về binaural beats và chú ý](https://pubmed.ncbi.nlm.nih.gov/39910150/)

Một số can thiệp bằng âm nhạc có thể hỗ trợ giảm cảm nhận đau trong những hoàn cảnh nhất định. Kết quả đó chưa xác lập tác dụng điều trị của riêng âm 174, 432 hoặc 528 Hz. [Tổng quan của NCCIH về âm nhạc và sức khỏe](https://www.nccih.nih.gov/health/providers/digest/music-and-health-science)

## Sử dụng

1. Để âm lượng thấp, chọn preset hoặc kéo mặt đĩa trong dải 16–20.000 Hz.
2. Bấm phát. Bạn có thể đổi tần số khi đang nghe. Bộ phát giữ pha liên tục và chuyển sang tần số mới trong 80 ms.
3. Chọn hẹn giờ để âm tự tắt sau 5, 15, 30 hoặc 60 phút. Bấm tạm dừng để kết thúc sớm.

Bấm **Tối giản** để mở Zen. Số Hz ở giữa hiển thị tần số hiện tại. Hàng bên dưới cho chọn nhanh 174, 432, 528 và 963 Hz; menu dấu ba chấm chứa đủ mười preset. Bấm nút tròn hoặc phím cách để phát/dừng. Nhấn **Esc** để về mặt đĩa hoặc dùng **⌘⇧M** để chuyển chế độ.

## Chạy từ mã nguồn

Cần macOS 15 trở lên và bộ công cụ Swift 6 trở lên. Dự án dùng Swift Package Manager và các framework hệ thống.

```sh
swift run
```

Để chạy test và tạo ứng dụng macOS ký ad-hoc trên máy:

```sh
swift test
scripts/build-mac.sh
open .build/AuraFreq.app
```

## Ngăn Làm việc

Bấm **Làm việc** để mở bảng bên cạnh mặt đĩa. Thêm công việc, chọn số phiên mục tiêu rồi bắt đầu. Mỗi phiên làm việc dài 25 phút, phiên nghỉ dài 5 phút. Khi hết giờ, bảng chuẩn bị pha kế tiếp để bạn tự bắt đầu. Chuyển task sẽ tạm dừng task cũ. Danh sách, tiến độ và thời gian còn lại được lưu trên máy.

Chọn White noise hoặc Brown noise và chỉnh âm lượng nền độc lập với sóng sin. Dán liên kết video vào mục YouTube và bấm **Phát video** để mở trình phát nhúng. Video cần kết nối mạng và được chủ sở hữu cho phép nhúng. **Giảm kích thích** thu gọn bảng về task và đồng hồ, đồng thời dừng video. Đóng ngăn vẫn cho phép phiên Pomodoro tiếp tục.

Trong mục YouTube, mở **Nhạc piano gợi ý** để phát [Clair de lune của Debussy](https://www.youtube.com/watch?v=WNcsUNKlAKw) hoặc [Gymnopédie số 1 của Satie](https://www.youtube.com/watch?v=2WfaotSK3mI), do Rousseau trình diễn. Đây là hai lựa chọn piano không lời để nghe trong phiên làm việc.

Cửa sổ tự thu gọn khi mở Zen và mở rộng khi bật ngăn Làm việc. Khi trở về mặt đĩa, app khôi phục kích thước studio trước đó.

Biểu tượng AuraFreq trên thanh menu macOS cho phép phát, tạm dừng, chọn preset và mở lại cửa sổ. Âm thanh tiếp tục khi đóng cửa sổ chính.

Trong menu **Preset**, dùng **Thêm preset…** để lưu tên và tần số tự chọn. Chọn một preset sẽ chỉnh tần số hiện tại. Danh sách được lưu cục bộ trên Mac và xuất hiện trong mục **Tần số** trên thanh menu.
