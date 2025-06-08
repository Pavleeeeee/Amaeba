extends Node2D

@export var Individuals: Array
@export var MainScene: PackedScene

var subViews = []
var numberOfIndividuals = 0
var generation = 0

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
		if score == null:
			score = 0
		self.score = score
		print("Score for ", name, ": ", score)
		if score > self.bestScore:
			self.bestScore = score
		self.gotScore.emit(self)


func shallowCopy(ind):
	var new_Ind = Individual.new(ind.genes.duplicate(), ind.name + "I")
	new_Ind.bestScore = ind.bestScore
	return new_Ind


func Ind_got_score(ind):
	for i in Individuals:
		if i.score < 0:
			return
	printerr("Done scoring")
	newGeneration()

func select(population):
	population.sort_custom(func(a, b): return a.score > b.score)
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
			if randf() <= 0.5:
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
	for i in range(len(population)):
		if randf() < 0.1:  # 10% šanse da se mutira
			var index = randi_range(0, 15)
			population[i].genes[index] = randf() - 0.5
			population[i].name += "M"
	return population

func newGeneration():
	generation += 1
	print("Generacija: ", generation)

	var population = []
	Individuals.sort_custom(func(ind1, ind2): return ind1.score > ind2.score)
	for i in Individuals:
		population.append(shallowCopy(i))

	population = mutate(cross(select(population)))
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
		population.append(Individual.new(createRandom(), "{" + str(i) + "}"))
		i += 1
		numberOfIndividuals += 1

	reset(population)

func _process(delta):
	pass
