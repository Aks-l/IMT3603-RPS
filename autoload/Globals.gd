extends Node

var inventory: Array[Hand] = []

func _ready():
	var rock: Hand = preload("res://path/to/stone.tres")
	var paper: Hand = preload("res://path/to/paper.tres")
	var scissor: Hand = preload("res://path/to/scissor.tres")
	
	inventory.append(rock)
	inventory.append(paper)
	inventory.append(scissor)
