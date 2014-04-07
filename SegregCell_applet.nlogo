globals [Time PopInitiale indiceGini SeuilDeClasse FortuneMoyenne MaxFortune Impot11 Impot12 Impot21 Impot22]
turtles-own [happy Sexe Age Richesse TauxDExposition Voisins VoisinsDifferents Quartier]
breed [ class1 ]
breed [ class2 ]


to setup ;Création de conditions initiales
	;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
	set-default-shape turtles "box"
	set PopInitiale (round (world-width * world-height * (pctcover / 100)))
  crt PopInitiale
  setup-plot
   	ask turtles [
      set breed class2 ;Toutes les tortues sont pauvres au départ.
		  AssigneSexe 
		  Classe 
		  set Age 115 - random 105 ;Assigne âge aléatoirement entre 10 et 100 ans.
		  set Richesse 50 ;Toute tortue a 50 unit�s au d�part.
		  set happy true
      placeUnique
      set heading 0
      if Impot [QuelQuartier]
    ]       	
end

to go ;Fonction it�rative qui fait tourner le programme
  set Time (Time + 1)
  set FortuneMoyenne (mean [Richesse] of turtles)
  set MaxFortune (round (max [Richesse] of turtles))
	set SeuilDeClasse ((SeuilClassePCT / 100) * FortuneMoyenne) ;x% de la moyenne de la fortune moyenne. si x=150, il faudra avoir 150% de la fortune moyenne pour �tre consid�r� comme riche.
	if Impot and (Time mod 4 = 0)[ ;n'est calcul� qu'une fois toutes les 4 it�rations pour �pargner le processeur...
      let NBTortues count turtles
	    let :PrixEntretien ((sum [Richesse] of turtles / 10)) ;; D�pend de l'inflation mesur�e le mieux par la somme de la fortune (la force d'achat reste constante)
	    ;; Dans les 4 lignes suivantes: calcul de l'imp�t individuel, exprim� en fraction de sa fortune
	    ;; que chaque habitant d'un quartier doit contribuer.
	    set Impot11 ((:PrixEntretien * (count turtles with [Quartier = 1.1] / NBTortues)) / (1 + (sum [Richesse] of turtles with [Quartier = 1.1]))) 
      set Impot12 ((:PrixEntretien * (count turtles with [Quartier = 1.2] / NBTortues)) / (1 + (sum [Richesse] of turtles with [Quartier = 1.2])))
      set Impot21 ((:PrixEntretien * (count turtles with [Quartier = 2.1] / NBTortues)) / (1 + (sum [Richesse] of turtles with [Quartier = 2.1])))
      set Impot22 ((:PrixEntretien * (count turtles with [Quartier = 2.2] / NBTortues)) / (1 + (sum [Richesse] of turtles with [Quartier = 2.2])))
	]
  ask turtles [goTurtles]
  do-plot
  if Time > 5200 [stop]
end

to voisinage
  set Voisins count (turtles-on neighbors)
  set VoisinsDifferents count (turtles-on neighbors) with [breed != [breed] of myself]
  ifelse Voisins = 0
      [set TauxDExposition 0]
      [set TauxDExposition (100 * (VoisinsDifferents / Voisins))]   
end

to goTurtles
  findhappy
  if not happy [placeUnique]
  EnrichirVieillir
  Classe
  if ((any? other turtles-here) and (Age > 90) and (random 20 > 7)) [placeUnique] ;� l'�ge de +- 80 it�rations, toute personne quitte le domicile familial.
  if ((Sexe = "femme") and (Age > 100) and (random 20 > 7)) [ChoosePartner] ;� l'age de +- 100 it�rations, l'individu recherche un partenaire pour former un couple.
  if Impot [QuelQuartier]
  voisinage
end

to QuelQuartier
  ifelse (xcor >= 0) [set Quartier 1] [set Quartier 2]
  ifelse (ycor >= 0) [set Quartier (Quartier + 0.1)] [set Quartier (Quartier + 0.2)]
end

to AssigneSexe
	ifelse (random 2) = 1 [set Sexe "femme"] [set Sexe "homme"] ;La probabilit� de naissances m�les est la m�me que la probabilit� de naissances femelles.
end

to Classe ;D�termine la classe d'une tortue et lui donne la couleur correspondante. ROUGE = classe2 = pauvre, VERT = classe1 = riche
	ifelse Sexe = "couple"
		[ifelse Richesse > SeuilDeClasse [set breed class1] [set breed class2]]
		[ifelse Richesse > SeuilDeClasse [set breed class1] [set breed class2]]	
	ifelse breed = class2
		[ifelse Sexe = "couple" 
			[set color grey set shape "box" ]
			[ifelse (Sexe = "femme") [set color grey set shape "femme"] [set color grey set shape "homme"]]
		]
		[ifelse Sexe = "couple" 
			[set color white set shape "box"]
			[ifelse (Sexe = "femme") [set color white set shape "femme"] [set color white set shape "homme"]]
		]
end

to EnrichirVieillir ;Viellissement et accumulation de richesses standard. avec mort par �ge
	set Richesse (Richesse + 2 - (TauxImpot * Richesse))
	set Age Age + 1
	if (Age > (400 - random 40)) [die];mort par �ge
end


to-report TauxImpot
  ifelse Impot and (Time mod 4 = 0)
    ;; Les co�ts de maintien d'un quartier sont fixes. 
    ;; Ils sont r�partis sur tous les habitants du quartier en termes d'un imp�t 
    ;; pourcentuellement �gal pour tous les habitants du quartier.	
    [ if Quartier = 1.1 [report Impot11]
      if Quartier = 1.2 [report Impot12]
      if Quartier = 2.1 [report Impot21]
      if Quartier = 2.2 [report Impot22]]
    [report 0]
end

to ChoosePartner ;Choix du partenaire  
  let Enfants (random GrowthRate)
  let partenaire one-of turtles with [(Sexe = "homme")]
  if partenaire = nobody [stop]
    if (([Age] of partenaire > 120) and ([Age] of partenaire < 290)) [
      if partenaire = nobody [stop]
      setxy [xcor] of partenaire [ycor] of partenaire
      if partenaire = nobody [stop]
		  set Richesse Richesse + [Richesse] of partenaire		  
		  set Sexe "couple"
		  if partenaire = nobody [stop]
		  ask partenaire [die]
		  if Enfants > 0 [
			  repeat Enfants [
			    hatch 1 [AssigneSexe set Age 0 set Richesse (Richesse / (2 * Enfants))]]
			  set Richesse Richesse / 2]
	    Classe
	  ]
end

to-report GrowthRate
  let NBtortues count turtles
  if ((NBtortues - 20) > PopInitiale) [report 3]
  if ((NBtortues + 20) < PopInitiale) [report 7]
  report 5
end

to findhappy
		  ifelse breed = class1 
		    [set happy (TauxDExposition < SeuilDeTolerance1)]
		    [set happy (TauxDExposition < SeuilDeTolerance2)]
end

to placeUnique
  setxy random world-width random world-height
  while [any? other turtles-here] [ set heading random 360 fd 1 ]
  set heading 0
  setxy pxcor pycor  ;; move to center of patch
end


;;POUR LES GRAPHIQUES

to setup-plot
    set-current-plot "Distribution de la Fortune"
      clear-plot
      set-plot-y-range 0 PopInitiale
      set-histogram-num-bars 10
    set-current-plot "Courbe de Lorenz"
      clear-plot
      set-current-plot-pen "égalité"
      plot 0
      plot 100
end

to do-plot 
   set-current-plot "Distribution de la Fortune" 
   ;set-plot-x-range 0 MaxFortune
   set-histogram-num-bars 10
   let class-range (MaxFortune / 10)
   let limite-basse 0
   let limite-haute (limite-basse + class-range)
   plot-pen-reset
   repeat 10 [
     let tortues-ici count turtles with [(Richesse >= limite-basse) and (Richesse < limite-haute)]
     ifelse ((limite-basse + 2) < SeuilDeClasse) [set-plot-pen-color red] [set-plot-pen-color green]
     plot tortues-ici
     set limite-basse (limite-basse + class-range)
     set limite-haute (limite-haute + class-range)
   ]

    
  set-current-plot "Courbe de Lorenz"
   clear-plot
   set-current-plot-pen "égalité"
   plot 0
   plot 100
  ;; on vient de dessiner la ligne d'�galit�
  set-current-plot-pen "lorenz"
  set-plot-pen-interval 100 / count turtles
  plot 0
  
  let sorted-wealths sort [Richesse] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  let gini-index-reserve 0

  ;; pour dessiner la courbe de Lorenz et partiellement calculer l'indice de Gini
  repeat length sorted-wealths [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    plot (wealth-sum-so-far / total-wealth) * 100
    set index (index + 1)    
    set gini-index-reserve (gini-index-reserve + (index / count turtles) - (wealth-sum-so-far / total-wealth))
  ]
  
  ;; finire de calculer et dessiner l'indice de Gini
  set-current-plot "Coefficients de Ségrégation"         
    set-current-plot-pen "Coef. Ségrégation Spatiale" plot SegregationSpatialeA
    set indiceGini ((gini-index-reserve / count turtles) / area-of-equality-triangle)
    set-current-plot-pen "Indice de Gini" plot indiceGini
    
end


;;MONITEURS ET ANALYSES:


to-report SegregationSpatialeA ;; calcule la proportion de tortues sans voisin diff�rent parmi toutes celles poss�dant un voisin
  report (1 - (count turtles with [VoisinsDifferents > 0] / count turtles with [Voisins > 0]))
end

to-report area-of-equality-triangle
  let NBTortues count turtles
  report (NBTortues * (NBTortues - 1) / 2) / (NBTortues ^ 2);; formule g�n�rale pour la somme x+(x-1)+(x-2)+(x-3)+...+(x-x)?
end



;;POUR FAIRE LES FILMS:

to makeMovieFile
movie-start "segregation.mov"
movie-set-frame-rate 10
end

to makeMovie
movie-grab-view go
end

to stopMovie
movie-close
end
@#$#@#$#@
GRAPHICS-WINDOW
14
171
372
550
25
25
6.824
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

SLIDER
14
10
323
43
pctcover
pctcover
0
100
60
1
1
%
HORIZONTAL

SLIDER
14
91
521
124
SeuilDeTolerance1
SeuilDeTolerance1
0
100
91
1
1
%
HORIZONTAL

BUTTON
338
10
398
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
404
10
459
43
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
129
520
162
SeuilDeTolerance2
SeuilDeTolerance2
0
100
70
1
1
%
HORIZONTAL

SLIDER
126
51
520
84
SeuilClassePCT
SeuilClassePCT
0
300
110
2
1
%
HORIZONTAL

MONITOR
378
380
543
425
Coef. Ségrég. Spat. (GRIS)
SegregationSpatialeA
3
1
11

PLOT
533
369
842
557
Coefficients de Ségrégation
Itération
Taux
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"Coef. Ségrégation Spatiale" 1.0 0 -7566196 true "" ""
"Indice de Gini" 1.0 0 -16776961 true "" ""

PLOT
534
10
841
187
Distribution de la Fortune
% Fortune
Nb. de ménages
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 10.0 1 -16776961 false "" ""

BUTTON
466
10
521
44
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
51
118
84
Impot
Impot
0
1
-1000

MONITOR
436
253
486
298
NIL
Impot12
3
1
11

MONITOR
436
198
486
243
NIL
Impot11
3
1
11

MONITOR
378
198
430
243
NIL
Impot21
3
1
11

MONITOR
379
253
430
298
NIL
Impot22
3
1
11

BUTTON
856
486
928
519
Enregistre
makeMovie
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
856
525
928
558
Stop
stopMovie
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
856
446
929
479
Make File
makeMovieFile
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
534
197
841
360
Courbe de Lorenz
Population (%)
Fortune (%)
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"lorenz" 1.0 0 -16711681 false "" ""
"égalité" 100.0 0 -16777216 true "" ""

MONITOR
379
492
525
537
Indice de Gini (BLEU)
indiceGini
3
1
11

@#$#@#$#@
Sociospatial segregation model by André Ourednik, EPFL
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 30 270 270 270 270 30 30 30

circle
true
0
Circle -7500403 true true 0 0 300

femme
false
0
Polygon -7500403 true true 30 270 270 270 270 30 30 270

homme
false
0
Polygon -7500403 true true 30 30 270 30 30 270 30 30

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
