FPS = 60

def spawn_target (args)
  size = 64
  {
    x: rand(args.grid.w * 0.4) + args.grid.w * 0.6,
    y: rand(args.grid.h - size * 2) + size,
    w: size,
    h: size,
    path: "sprites/target.png"
  }
end

def fire_input?(args)
  args.inputs.keyboard.key_down.j
end

def handle_player_movement(args)
   # character input 
   if args.inputs.left 
    args.state.player.x -= args.state.player.speed
  elsif args.inputs.right
    args.state.player.x += args.state.player.speed
  end

  if args.inputs.up
    args.state.player.y += args.state.player.speed
  elsif args.inputs.down
    args.state.player.y -= args.state.player.speed
  end

  # character boundary (width)
  if args.state.player.x + args.state.player.w > args.grid.w
    args.state.player.x = args.grid.w - args.state.player.w
  end

  # character default x position
  if args.state.player.x < 0
    args.state.player.x = 0
  end

  # character boundary (height)
  if args.state.player.y + args.state.player.h > args.grid.h
    args.state.player.y = args.grid.h - args.state.player.h
  end

  # character default y position
  if args.state.player.y < 0
    args.state.player.y = 0
  end
end

HIGH_SCORE_FILE = "high-score.txt"
def game_over_tick(args)
  args.state.high_score ||= args.gtk.read_file(HIGH_SCORE_FILE).to_i


  if args.state.saved_high_score && args.state.score > args.state.high_score 
    args.gtk.write_file(HIGH_SCORE_FILE, args.state.score.to_s)
    args.state.saved_high_score = true
  end

  labels = []
  labels << {
    x: 40,
    y: args.grid.h - 48,
    text: "Game Over!",
    size_enum: 10,
  }
  labels << {
    x: 40,
    y: args.grid.h - 90,
    text: "Score: #{args.state.score}",
    size_enum: 4,
  }
  labels << {
    x: 40,
    y: args.grid.h - 132,
    text: "Fire to restart",
    size_enum: 2,
  }
  if args.state.score > args.state.high_score
    labels << {
    x: 260,
    y: args.grid.h - 90,
    text: "New high-score!",
    size_enum: 3,
    }
  else
    labels << {
    x: 260,
    y: args.grid.h - 90,
    text: "Score to beat: #{args.state.high_score}",
    size_enum: 3,
    }
  end

  args.outputs.labels << labels

  if args.state.timer < -30 && args.inputs.keyboard.key_down.j
    $gtk.reset
  end
end

def tick args
  args.state.scene ||= "gameplay"
  # set background
  args.outputs.solids << {
    x: 0,
    y: 0,
    w: args.grid.w,
    h: args.grid.h,
    r: 92,
    g: 120,
    b: 230,
  }

  # set character
  args.state.player ||= {
    x: 120,
    y: 120,
    w: 100,
    h: 80,
    speed: 12,
  }

  # animating character
  player_sprite_index = 0.frame_index(count: 6, hold_for: 8, repeat: true)
  args.state.player.path = "sprites/misc/dragon-#{player_sprite_index}.png"

  # set fireball
  args.state.fireballs ||= []

  #set target
  args.state.targets ||= [
    spawn_target(args), spawn_target(args), spawn_target(args)
  ]

  #set score
  args.state.score ||= 0
  #set timer
  args.state.timer ||= 30 * FPS

  args.state.timer -= 1

  if args.state.timer < 0
    game_over_tick(args)
    return
  end

  # handle player movement
  handle_player_movement(args)

  # character input for fireball
  if fire_input?(args)
    args.state.fireballs << {
      x: args.state.player.x + args.state.player.w - 12,
      y: args.state.player.y + 10,
      w: 64,
      h: 64,
      path: 'sprites/fireball.png',
    }
  end

  # enables fireball to move in a direction
  args.state.fireballs.each do |fireball|
    fireball.x += args.state.player.speed + 2

    if fireball.x > args.grid.w 
      fireball.dead = true
      next 
    end

     # detects fireball and target collision
    args.state.targets.each do |target| 
      if args.geometry.intersect_rect?(target, fireball)
        target.dead = true 
        fireball.dead = true
        args.state.score += 1
        args.state.targets << spawn_target(args)
      end
    end
  end


  args.state.fireballs.reject!{ |f| f.dead }
  args.state.targets.reject!{ |t| t.dead }

  # renders sprites
  args.outputs.sprites << [args.state.player, args.state.fireballs, args.state.targets  ]

  labels = []

  # display score
  labels << {
  x: 40,
  y: args.grid.h - 40,
  text: "Score: #{args.state.score}",
  size_enum: 4,
  }

  # display timer
  labels << {
  x: args.grid.w - 40,
  y: args.grid.h - 40,
  text: "Time Left: #{(args.state.timer / FPS).round}",
  size_enum: 2,
  alignment_enum: 2,
  }

 args.outputs.labels << labels
end

# reloads code
$gtk.reset