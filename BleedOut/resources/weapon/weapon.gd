extends Resource

class_name WeaponData

enum Type {melee_blunt, melee_sharp, second, pistol}

@export var name: String
@export var damage: float
@export var scene: PackedScene
@export var type: Type

@export var mag_cap: int
@export var max_mag: int
@export var spare_ammo: int
@export var max_spare: int
@export var fire_rate: float
