
Aksel Wiersdalen

# IMT3603 Individual submission. 

Since this is an individual submission, I assume that i should only talk about my own code, therefore I will only speak about code I have written myself, and not talk about what the other group members have written.

## [Code Repository](https://github.com/Aks-l/IMT3603-RPS)
## [Gameplay Video](https://youtu.be/4VFcysTtJPU)

### Good code
Generally speaking, i consider good code to be compact and reusable. It does not have to be a large complex function, but rather small functions that do one thing very well, without creating noise.

The code I wrote that I am most proud of is the function that decides the winner of a match. What makes this so good is that it is decided by a compact one liner that is very modular. The function has no extra noise, and can be used from anywhere in the code, as it is used as an autoload singleton.

It is not only compact, but it utilizes the fundamentals of how rock-paper-scissors work, in that when ordered in a circle, each hand beats exactly the next half circle of hands, and loses to the rest. This means that it only needs an odd amount of hands, and that all IDs are properly set. The exact same function would work equally well if there were 3 or 1001 hands. 

The function simply gets two hands as input, and returns an integer based on the result. It is used during combat, and is the engine behind the hand-graph accessible from everywhere.

```py
func get_result(hand_a: HandData, hand_b: HandData) -> int:
    var num_hands = HandDatabase.hands.size()
    var result_bool: bool = (hand_a.id - hand_b.id + num_hands) % num_hands > int(num_hands / 2) 
    # tie condition
    if hand_a.id == hand_b.id: return 0
    # win/loss
    if result_bool: return 1  # hand_a wins
    else:           return -1 # hand_a loses
```

Another part of the code base i consider good is the architecture of loading data in the start of the game. This code structure is used to load all the data, including enemies, hands, items, events and biomes. It was originally written to import hands and enemies, but its simplicity made us use it for the other datas as well.

It iterates through a target folder, and loads all `.tres` files found there. The files are stored in a dictionary that is available globally, with the ID as key. This means that all data can be accessed from anywhere in constant time. Here is the code for loading enemies as an example:

```py
var enemies: Dictionary = {}

func load_enemies():
  var dir = DirAccess.open("res://data/enemies")
  if dir:
    for file in dir.get_files():
      if file.ends_with(".tres"):
        var enemy = load("res://data/enemies/" + file)
        if enemy and enemy is EnemyData:
          enemies[enemy.id] = enemy
```

The final good code i want to highlight is the animation that happens when a battle is played out. Here it is not only the code, but the way it was solved that I want to spotlight. The two played hands per match move toward each other and the loser explodes on impact. Originally I wanted to have one winning-animation per hand, for example cutting the loser in two for scissors, and burning the loser for fire. I think this would be very cool for a full release, but this would be way too time consuming for this project, and I settled with only one shared animation for all hands.

I spent a while searching for how I could make an image explode into pieces, but I found out that the best way to do it would be to replace the image with [a pre-made object that consists of multiple small rigid bodies.](https://www.youtube.com/watch?v=nlt6__j0T-c) The hands that fight are instantiated as RigidBodies with an initial velocity toward each other. When they collide, the losing hand is deleted and replaced by the "dead" object that consists of many smaller parts. Each of these parts is also a RigidBody, but without a hitbox, so that they can be given a pseudo random velocity to simulate an explosion. 

This is also the only part of the game where I was worried about performance, as up to 100 physics bodies would suddenly appear all at once during an explosion. After some research on this, I realized that Godot actually handles this very well, [even better than other engines like Unity](https://www.youtube.com/watch?v=GPgkW0h4r1k) when it comes to 2D.

For this code, I also scaled all involved pieces to the viewport size, to make sure the images' size, location, speed and the same for the explosion, would work the same on all screen sizes.

Error handling has been removed from the example to highlight the core logic:

```py
func kill_hand(hand: RigidBody2D) -> void:

	var dead_instance := dead.instantiate()
	parent.add_child(dead_instance)

	var vw = get_viewport_rect().size.x
	(dead_instance as Node2D).scale = Vector2.ONE * (vw/2000)

	dead_instance.position = parent.to_local(loser_sprite.global_position)

	var base_speed_x = _battle_speed if hand == hand1 else -_battle_speed

	for piece in dead_instance.get_children():
		if piece is RigidBody2D:
			var body_piece := piece as RigidBody2D
			var x_mult := randf_range(0.8, 1.2)
			var vx := base_speed_x * x_mult
			var vy := randf_range(-_battle_speed * 0.3, _battle_speed * 0.3)
			body_piece.linear_velocity = Vector2(vx, vy)

	hand.queue_free()
```

### Bad Code

When it comes to bad code, I feel like it is always due to a lack of time. If there are any obvious bad code, it should get fixed, and the main reason why it isn't is in our case because we wanted to prioritize more features over cleaning up code.

The most obvious bad code example in my opinion is the battle_ui script. There are way too many things crammed into one script. The functions `_setup()` function has too many unnecessary instructions to set up inventory and deal with enemy data. This could be split up into smaller functions, as well as getting data from globals instead of parameters, or at least use globals as default values where possible.

In addition to that, the way `_apply()` is "deferred" looks messy. It would be better to drop the additional flag variables, and rather make sure that the `_ready()` and `_setup()` functions are always called in the right order.

```py
var _has_params := false
var _is_ready := false

func setup(enemy: EnemyData, ...):
    # ... code ...
    _has_params = true
    if _is_ready:
        _apply()

func _ready():
    # ... code ...
    _is_ready = true
    if _has_params:
        _apply()
```

Many script files are also littered with leftover comments and debug code that should be removed. In battle_ui.gd, for example, some old codes are commented out instead of deleted, making the code overall harder to read, and in turn harder to debug. I am also not satisfied with the naming conventions of folders and files, as there are inconsistencies in the use of snake_case, `encounter_icons` and `map_textures`, PascalCase, `FightScene` and `DeckCreator`, and camelCase `eventScene` and `mainMenu`. This is an issue that is easy to fix, but was not prioritized due to time constraints.



## Personal Reflection

The main thing I am taking away from this project is a good understanding of the Godot engine, especially the scene system and control node hierarchy. I have experienced that in the latter part of the semester, I was much more experienced with all the size and positioning flags, making it much less time consuming to set up new scenes. As our game is mostly UI based and can be controlled using only the mouse, this became very important.

I have also gotten more efficient with the GDScript language. This was not a big obstacle, however, as I had previous experience with python, which has a very similar syntax. The biggest difference is how important the object oriented programming is in Godot. There was a challenge in the beginning to understand the built-in functions like `_ready()`, `_process()`, as well as all properties and signals of nodes that are always "just there", but after understanding them, it became second nature. It was also a big help that I used Godot in other projects this semester as well.

A challenge during development was to figure out how to make the game engaging and fun to play. From the start, I drew a lot of inspiration from [Balatro](https://store.steampowered.com/app/2379780/Balatro/), which is a poker based deck builder. I wanted to create a similar experience, but with rock-paper-scissors instead. The challenge in our concept, however, was that it is much more luck based and randomized then Balatro. Therefore we needed a way to give the player an edge over the enemies to counter the randomness. This was eventually solved by giving the enemies a set moveset, and although not directly told to the player, it can be discovered through repeated encounters that the enemies does not just play random hands from a set, but actually has its own inventory of hands that is consumed during battle. This allows the player to have an edge after playing for a bit, even if they cannot predict which enemy is the next to combat. 

When it comes to the art assets in the game, ie. backgrounds and the images for enemies and hands, they are all generated by ChatGPT. I decided that the time it would take to create everything myself, given that there are over 100 hands, would be way too time consuming. Still, the generated images, especially the backgrounds came out really well, and set a fitting atmosphere to the game. There is some debate that this should not be done, especially from the art community, but the course description says it encourages generative AI, and I personally believe that the result matters way more than the method of creation.

After this project, my view on game development has changed some. I never thought it was easy, but given that our game is relatively small, I was surprised at how much work it required. As opposed to creating a functional application, the game also needs extra care to ensure that it is fun, and that *everything* works as intended. If one thing does not work, the entire experience falls apart. If a studio announces a release day for a game, I can now imagine how hard the developers must be working, if the game is not already finished. It also became an extra challenge given that one of our original team members stopped working early in the semester, increasing the workload on the rest as we didn't want to reduce the scope.

When it comes to our final product, I would classify it as playable, but not completed. There are several things we still want to implement, like more story-related interactions with enemies. They have the ability to *talk* through a dialogue box, and it would be fun to make the enemies speak different lines based on how many interactions the player has had with them, allowing lots of lore to be added to this world, and further incentivizing further play and reduce repetition. Of course, there is also the big missing feature that are items, which currently can only be purchased and used, but don't actually have an effect. Still, considering the time frame, and given that is a 7.5 ECTS project, I am very satisfied with the end result.

## Rubric Notes

The submission requires me to choose weights for each part of the submission. I have chosen the following weights:

| Submission part | Weight |
|-----------------|--------|
| Gameplay video | 20% |
| Code video | 0% |
| Good code | 20% |
| Bad code | 10% |
| Development Process | 25% |
| Reflection | 25% |

I cover the code parts in the good and bad code sections, therefore no code video is provided. The gameplay video's weight is increased to its maximum, and the bad code weight is reduced to increase the weight of the development process and reflection.