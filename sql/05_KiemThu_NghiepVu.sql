/* ==========================================================================
   FILE 05 : Kịch bản kiểm thử nghiệp vụ (dùng để DEMO khi báo cáo)
   Mỗi kịch bản chạy trong giao dịch riêng và ROLLBACK ở cuối -> dữ liệu mẫu
   không bị thay đổi, chạy lại bao nhiêu lần cũng được.
   Xem kết quả ở tab Results và thông báo ở tab Messages của SSMS.
   ========================================================================== */
USE QLCuaHangTienLoi;
GO
SET NOCOUNT ON;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 1: Bán hàng cho khách thành viên KH02 (hạng Vàng, giảm 5%)
   Kỳ vọng: tồn kho SP01 giảm 2, SP05 giảm 3; hóa đơn được giảm 5%
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 1: Bán hàng cho khách thành viên =====';
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MaHD INT;

    SELECT MaKH, HoTen, DiemTichLuy, TenHang, PhanTramGiam
    FROM v_KhachHangThanhVien WHERE MaKH = 'KH02';

    SELECT MaSP, TenSP, SoLuongTon AS TonTruocKhiBan FROM SanPham WHERE MaSP IN ('SP01', 'SP05');

    EXEC sp_TaoHoaDon @MaNV = 'NV02', @SoDienThoaiKH = '0971000002',
                      @PhuongThucTT = N'Ví điện tử', @MaHD = @MaHD OUTPUT;
    PRINT CONCAT(N'Đã tạo hóa đơn số ', @MaHD);

    EXEC sp_ThemSanPhamVaoHoaDon @MaHD, '8930000000011', 1;  -- quét mã vạch Coca-Cola
    EXEC sp_ThemSanPhamVaoHoaDon @MaHD, '8930000000011', 1;  -- quét lần nữa -> cộng dồn thành 2
    EXEC sp_ThemSanPhamVaoHoaDon @MaHD, 'SP05', 3;           -- nhập theo mã sản phẩm

    SELECT MaSP, TenSP, SoLuongTon AS TonSauKhiBan FROM SanPham WHERE MaSP IN ('SP01', 'SP05');

    EXEC sp_ThanhToanHoaDon @MaHD;   -- 56.000đ - 5% = 53.200đ
END TRY
BEGIN CATCH
    PRINT CONCAT(N'LỖI không mong đợi: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 2: Bán vượt tồn kho -> trigger chặn
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 2: Bán vượt tồn kho =====';
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MaHD INT;
    EXEC sp_TaoHoaDon @MaNV = 'NV03', @MaHD = @MaHD OUTPUT;
    EXEC sp_ThemSanPhamVaoHoaDon @MaHD, 'SP16', 50;      -- dầu gội chỉ còn 2 chai
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - bị chặn: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 3: Thêm hàng vào hóa đơn đã thanh toán -> trigger chặn
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 3: Sửa hóa đơn đã thanh toán =====';
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO ChiTietHoaDon (MaHD, MaSP, SoLuong, DonGiaBan) VALUES (1, 'SP02', 1, 6000);
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - bị chặn: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 4: Hủy hóa đơn 17 (khách trả hàng) -> hoàn tồn kho
   Kỳ vọng: SP08 +10, SP18 +2, SP03 +2
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 4: Hủy hóa đơn số 17 =====';
BEGIN TRANSACTION;
BEGIN TRY
    SELECT MaSP, TenSP, SoLuongTon AS TonTruocKhiHuy FROM SanPham WHERE MaSP IN ('SP03', 'SP08', 'SP18');
    EXEC sp_HuyHoaDon @MaHD = 17, @LyDo = N'Khách trả hàng';
    SELECT MaSP, TenSP, SoLuongTon AS TonSauKhiHuy   FROM SanPham WHERE MaSP IN ('SP03', 'SP08', 'SP18');

    -- Hủy lần 2 -> bị chặn
    EXEC sp_HuyHoaDon @MaHD = 17, @LyDo = N'Thử hủy lại';
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - hủy lần 2 bị chặn: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 5: Nhập hàng bổ sung cho sản phẩm sắp hết
   Kỳ vọng: SP16 tồn 2 -> 14, biến mất khỏi v_SanPhamCanNhap
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 5: Nhập hàng bổ sung =====';
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MaPN INT;

    SELECT * FROM v_SanPhamCanNhap;

    EXEC sp_TaoPhieuNhap @MaNCC = 'NCC04', @MaNV = 'NV04',
                         @GhiChu = N'Bổ sung dầu gội', @MaPN = @MaPN OUTPUT;
    INSERT INTO ChiTietPhieuNhap (MaPN, MaSP, SoLuong, DonGiaNhap, HanSuDung)
    VALUES (@MaPN, 'SP16', 12, 53000, '2028-12-31');

    SELECT * FROM v_SanPhamCanNhap;
END TRY
BEGIN CATCH
    PRINT CONCAT(N'LỖI không mong đợi: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 6: Nhân viên đã nghỉ việc lập hóa đơn -> procedure chặn
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 6: Nhân viên đã nghỉ lập hóa đơn =====';
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @MaHD INT;
    EXEC sp_TaoHoaDon @MaNV = 'NV06', @MaHD = @MaHD OUTPUT;
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - bị chặn: ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* --------------------------------------------------------------------------
   KỊCH BẢN 7: Vi phạm ràng buộc UNIQUE và CHECK
   -------------------------------------------------------------------------- */
PRINT N'===== KỊCH BẢN 7: Vi phạm ràng buộc =====';
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO KhachHang (MaKH, HoTen, SoDienThoai) VALUES ('KH99', N'Trùng SĐT', '0971000001');
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - bị chặn (UNIQUE số điện thoại): ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO NhanVien (MaNV, HoTen, GioiTinh, NgaySinh, SoDienThoai, NgayVaoLam, MaCV)
    VALUES ('NV99', N'Chưa đủ tuổi', N'Nam', '2010-01-01', '0999999999', '2026-10-08', 'CV02');
    PRINT N'SAI: lẽ ra phải báo lỗi';
END TRY
BEGIN CATCH
    PRINT CONCAT(N'ĐÚNG - bị chặn (CHECK đủ 18 tuổi): ', ERROR_MESSAGE());
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

PRINT N'===== Hoàn tất kiểm thử, dữ liệu mẫu giữ nguyên =====';
GO
