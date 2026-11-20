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
