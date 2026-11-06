-- Script Stored Procedure trong PostgreSQL / SQL Server cho hệ thống SmartDroneDelivery
CREATE OR REPLACE PROCEDURE sp_DuyetVaPhanCongDonHang(
    IN p_OrderId INT,
    IN p_StationId INT,
    IN p_DroneId INT,
    OUT p_ResultStatus VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_CurrentStatus VARCHAR(50);
BEGIN
    -- Kiểm tra trạng thái hiện tại của đơn hàng
    SELECT status INTO v_CurrentStatus FROM orders WHERE id = p_OrderId;
    
    IF v_CurrentStatus IS NULL THEN
        p_ResultStatus := 'ERROR: Không tìm thấy đơn hàng!';
        RETURN;
    END IF;

    IF v_CurrentStatus != 'Pending' THEN
        p_ResultStatus := 'ERROR: Đơn hàng đã được duyệt hoặc đang xử lý trước đó!';
        RETURN;
    END IF;

    -- Tiến hành cập nhật phân công đơn hàng
    UPDATE orders
    SET 
        status = 'Approved',
        pickup_station_id = p_StationId,
        assigned_drone_id = p_DroneId,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_OrderId;

    -- Cập nhật trạng thái Drone thành đang làm nhiệm vụ
    UPDATE drones
    SET status = 'Assigned'
    WHERE id = p_DroneId;

    p_ResultStatus := 'SUCCESS: Duyệt và phân công đơn hàng thành công!';
END;
$$;