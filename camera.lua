function update_camera()

  cam_x=player.x-64+(player.w/2)
  if cam_x<map_start then
    cam_x=map_start
  end
  if cam_x>map_end-128 then
    cam_x=map_end-128
  end

  if score < 20 then

    cam_y=player.y-64

    if cam_y<map_floor then
      cam_y=map_floor
    end
    if cam_y>map_ceiling-128 then
      cam_y=map_ceiling-128
    end
  
  elseif score >= 40 then

    cam_y-=0.4
  elseif score >= 20 then

    cam_y=player.y-64

    if not camera_locked then
      camera_min_y = cam_y 
      camera_locked = true
    end

    if cam_y > camera_min_y then
      cam_y = camera_min_y
    else
      camera_min_y = cam_y
    end
  end
  

  camera(cam_x,cam_y)
end

