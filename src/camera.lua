function update_camera()

  -- horizontal camera follows player, clamped to map bounds
  cam_x = player.x - 64 + (player.w/2)
  if cam_x < map_start then cam_x = map_start end
  if cam_x > map_end - 128 then cam_x = map_end - 128 end

    -- vertical camera only moves up (with player), never back down
    local desired_cam_y = player.y - 64 + (player.h/2)

    if camera_min_y == nil then
      camera_min_y = desired_cam_y   
    end

    if desired_cam_y > camera_min_y then
      cam_y = camera_min_y           
    else
      camera_min_y = desired_cam_y  
      cam_y = desired_cam_y
    end

  -- auto-scroll kicks in past score thresholds, speeding up over time
  if score > 200 then
    auto_scroll_active = true
  end

  if score > 300 and auto_scroll_active then
    auto_scroll_speed = 0.2
  end

  if score > 400 and auto_scroll_active then
    auto_scroll_speed = 0.3
  end

  if score > 500 and auto_scroll_active then
    auto_scroll_speed = 0.4
  end

  -- forces camera upward regardless of player position once active
  if auto_scroll_active then
    camera_min_y -= auto_scroll_speed   
    if camera_min_y < cam_y then
        cam_y = camera_min_y
    end
  end

  camera(cam_x, cam_y)
end