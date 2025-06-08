extends Node2D

@export var Individuals: Array
@export var MainScene: PackedScene

var subViews = []
var numberOfIndividuals = 0

func createRandom():
	var reflexMatrix = []
	for i in range(16):
		reflexMatrix.append(randf() - 0.5)
	return reflexMatrix

class Individual extends Object:
	var name = ""
	var genes = []
	var representation: Area2D = null
	var score = -1
	var bestScore = 0

	signal gotScore(individual: Individual)

	func _init(genes, name):
		self.genes = genes
		self.name = name

	func getScore(score):
		self.score = score
		print(self.score)
		print("got score")
		if score > self.bestScore:
			self.bestScore = score
		self.gotScore.emit(self)

func shallowCopy(ind):
	var new_Ind = Individual.new(ind.genes.duplicate(), ind.name)
	new_Ind.bestScore = ind.bestScore
	return new_Ind

func Ind_got_score(ind):
	var count = 0
	for i in Individuals:
		if i.score < 0:
			count += 1
	if count == 0:
		print("done scoring")
		newGeneration()

func select(population):
	population.sort_custom(func(ind1, ind2): return ind1.score > ind2.score)
	var chosen = []
	for i in range(int(len(population) / 2)):
		chosen.append(population[i])
	return chosen

func cross(population):
	var children = []
	for p in population:
		children.append(p)
	for parent1 in population:
		var parent2 = population[randi_range(0, len(population) - 1)]
		var child1 = []
		var child2 = []
		for i in range(16):
			var odabir = randf()
			if odabir <= 0.5:
				child1.append(parent1.genes[i])
				child2.append(parent2.genes[i])
			else:
				child2.append(parent1.genes[i])
				child1.append(parent2.genes[i])
		children.append(Individual.new(child1, str(numberOfIndividuals)))
		numberOfIndividuals += 1
		children.append(Individual.new(child2, str(numberOfIndividuals)))
		numberOfIndividuals += 1
	return children

func mutate(population):
	var mutated = population[randi_range(0, len(population) - 1)]
	var index = randi_range(0, 15)
	mutated.genes[index] = randf() - 0.5
	mutated.name += "M"
	return population

func newGeneration():
	var population = []
	Individuals.sort_custom(func(ind1, ind2): return ind1.score > ind2.score)

	var elite_count = 4
	var total_count = len(subViews)

	for i in range(elite_count):
		population.append(shallowCopy(Individuals[i]))

	var selected = select(Individuals)
	var children = cross(selected)
	var mutated = mutate(children)

	var needed = total_count - elite_count

	for i in range(needed):
		var ind = mutated[i]
		ind.name = str(numberOfIndividuals)
		numberOfIndividuals += 1
		ind.bestScore = 0
		population.append(ind)

	reset(population)

func reset(population):
	for v in subViews:
		for n in v.get_children():
			v.remove_child(n)
			n.queue_free()
	Individuals = []
	for i in range(len(subViews)):
		var ms = MainScene.instantiate()
		var ind = population[i]
		ind.representation = ms
		Individuals.append(ind)
		ind.gotScore.connect(Ind_got_score)
		ms.reflexMatrix = ind.genes
		ms.gameover.connect(ind.getScore)
		ms.NameLabel = ind.name
		ms.BestScore = ind.bestScore
		subViews[i].add_child(ms)

func _ready():
	seed(43)
	var gridchildren = $GridContainer.get_children()
	subViews = []
	for g in gridchildren:
		subViews.append(g.get_child(0))
	var population = []
	var i = 0
	for m in subViews:
		population.append(Individual.new(createRandom(), str(i)))
		i += 1
		numberOfIndividuals += 1
	reset(population)

func _process(delta):
	pass
