extends Area2D

func is_colliding():
  var areas = get_overlapping_areas()
  return areas.size() > 0

func get_push_vector():
  var areas = get_overlapping_areas()
  var pushVector = Vector2.ZERO
  
  if is_colliding():
    var area = areas[0]
    pushVector = area.global_position.direction_to(global_position)
    pushVector = pushVector.normalized()
    
  return pushVector
