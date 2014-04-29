breed [places place]
breed [specialists specialist]

patches-own [peasants mysugar initSugar production-factor neighborhood
    parentStep psugar processed-sugar] ; psugar = potential-sugar
places-own [population sugar famine]
specialists-own [mycity sugar]
globals [
    nbPlaces nbspecialists nbPeasants sugarRange ageRange
    steps  includeMyPatch?
    scapeColor geometryScape? randAgents? agentLayout cultureTags useK? total indiceGini
    maxPsugar 
    ] ;  Chaque agent consomme 1 unit� de sucre par it�ration.   
; -- setup/initialization procedures --

to setup
    ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
    globals-defaults
    set-default-shape places "circle"
    if presets != "manual" [
      set growback item 0 item 1 presets 
      set global-reach item 1 item 1 presets
      set specialist-effect item 2 item 1 presets
    ]
    ask patches [
      set psugar 10
      set peasants 10 
      set pcolor scapeColor]
    ;create-specialists 10
    found-city
    setup-plot
    semantique
end

to globals-defaults
    set scapeColor      yellow    ; orange or other dark color makes scape clearer, yellow is usual.
    set maxPsugar 10 
end

to setup-specialist
  set hidden? true
  ifelse count places > 0 ; un facteur stochastique pour la fondation des villes
    [set mycity one-of places] 
    [set mycity nobody]
end



;;;;---GO----;;;;;;;;;;;;;;;;;;;;;;;

to go
    set steps steps + 1
    ask places [set population count specialists-here]
    ask patches [step-patches] 
    ask places [step-places] 
    if count specialists with [mycity = nobody] > 0 [found-city] ;la proc�dure found-city se retrouve au niveau de la proc�dure, pas au niveau des agents
    semantique
    set nbPlaces count places
    set nbspecialists count specialists
    set nbPeasants sum [peasants] of patches
    do-plot
    if nbspecialists + nbPeasants = 0 [ask turtles [extinction]]
end

to step-patches 
    set production-factor 0.9 + sum [1 / (1 + 2.71828183 ^ exponent)] of places with [distance myself <= global-reach] ; Le production-factor fixe avant tout la contribution des sp�cialistes � la vie des paysans. La fonction logistique sigmoide est utilis�e. 
    let production peasants * production-factor * ((random 200) / 100) * growback ; on introduit quand m�me un facteur stochastique dans la r�colte  
    set psugar psugar + production 
    if psugar > maxPsugar [set psugar maxPsugar] ; la nouriture stock�e dans un patch poss�de une limite donn�e par maxPsugar
    let i peasants
    while [i > 0][
      ifelse psugar >= 1 [set psugar psugar - 1] [set peasants peasants - 1] ; S'il n'y a pas assez de sucre, on tue les paysans exc�dentaires
      set i i - 1]  
    if psugar >= 1 [
      ifelse random 100 < 3 ; la probabilit� de cr�ation d'un sp�cialiste est de 3% 
        [sprout-specialists 1 [setup-specialist]] 
        [ask one-of neighbors [set peasants peasants + 1]] 
      set psugar psugar - 1] 
end

to-report exponent
    let expn (-1 * population * (specialist-effect - 200) / 100)
    if (expn > 700) [set expn 700] ; autrement, on obtient des chiffres trop grands
    report expn
end

to step-places
    set population count specialists with [mycity = myself]
    if population < 1 [die]
    let myland patches with [distance myself <= global-reach and psugar >= 1] 
    let ernte sum [psugar] of myland
    ifelse ernte < population 
      [ 
        set famine true
        ask n-of (population - ernte) specialists with [mycity = myself] [leaveOrDie]
      ]
      [
        set famine false
        let i population 
        while [i > 0] [
          ask one-of myland [set psugar psugar - 1] 
          set i i - 1]
        ask n-of (population / 20) specialists with [mycity = myself] [findLarger]        
      ]

end

to leaveOrDie 
      if random 100 < 40 [die]
      let mypotentialcity one-of places with [not famine] ; and population < population-of mycity-of myself and 
      ifelse mypotentialcity != nobody 
        [set mycity mypotentialcity] 
        [set mycity nobody] ; la probabilit� de mourir si on n'a plus de ville est de 5%
      ;return-home
end

to findLarger
      let myoldcity mycity
      let mypotentialcity one-of places with [population >= [population] of [mycity] of myself and not famine]
      ifelse mypotentialcity != nobody [set mycity mypotentialcity] [set mycity myoldcity] 
      ;return-home
end

to found-city 
      let potential-place one-of patches            
      create-places 1 [
         setxy [pxcor] of potential-place [pycor] of potential-place  
         set hidden? false
         set population 1 
         set color grey - 3 
         set famine false
         ask specialists with [mycity = nobody] [set mycity myself]
      ]
end




; --- Utilities ---


to-report shuffle-old [a] ; Utility from Seth for randomizing an agent set
    let shuffled 0
  
    set shuffled [self] of a
    ;set shuffled sort-by [random 2 = 0] shuffled
    set shuffled shuffle-list shuffled
    report shuffled
end

to-report shuffle-list [input-list] ; from Seth
   report map [item 1 ?]                       ;; discard tags
              sort-by [first ?1 < first ?2]    ;; sort by tags
                      map [list random 1.0 ?]  ;; add tags
                          input-list
end


to semantique
  ask places [set color grey - 3 set size population / 300 + 1]
  ask patches [set pcolor scale-color scapeColor peasants 20 0]
end


to setup-plot
  set-current-plot "Lorenz Curve City Sizes"
      clear-plot
      set-current-plot-pen "equality"
      plot 0
      plot 100
end


to do-plot 
      
   set-current-plot "Lorenz Curve City Sizes"
     if nbPlaces < 1 [stop]
     clear-plot 
     set-current-plot-pen "equality"
     plot 0 plot 100 ;; on vient de dessiner la ligne d'�galit�
     set-current-plot-pen "lorenz"
     set-plot-pen-interval 100 / nbPlaces
     plot 0
  
  let sorted-populations sort [population] of places
  let total-population sum sorted-populations
  let wealth-sum-so-far 0
  let index 0
  let gini-index-reserve 0

  ;; pour dessiner la courbe de Lorenz et partiellement calculer l'indice de Gini
  repeat length sorted-populations [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-populations)
    plot (wealth-sum-so-far / total-population) * 100
    set index (index + 1)    
    set gini-index-reserve (gini-index-reserve + (index / nbPlaces) - (wealth-sum-so-far / total-population))
  ]
  
  
  ;; finir de calculer et dessiner l'indice de Gini sur l'autre plot
  set-current-plot "Gini Index City Sizes"
    ifelse area-of-equality-triangle > 0 and nbPlaces > 0
      [set indiceGini ((gini-index-reserve / nbPlaces) / area-of-equality-triangle)]
      [set indiceGini 0]    
    set-current-plot-pen "Gini Index" plot indiceGini
  
  set-current-plot "Agents"
    set-current-plot-pen "Specialists" plot nbspecialists
    set-current-plot-pen "Peasants" plot sum [peasants] of patches 
  
  set-current-plot "% urban population"
    ifelse (nbPeasants + nbSpecialists) >= 1 
    [plot nbspecialists / (nbPeasants + nbSpecialists) * 100]
    [plot 0]
  
  set-current-plot "Number of Cities"
    plot nbPlaces
  
  
    set-current-plot "City Sizes"
      let bars 0
      set-current-plot-pen "default" 
      plot-pen-reset
      set-plot-pen-mode 1
      let maxpop max [population] of places
      set-plot-x-range 0 maxpop
      ifelse (nbPlaces < 5) 
       [set bars (nbPlaces - 1)]
       [set bars 5]
      if (bars < 1) [set bars 1]
      set-histogram-num-bars bars
      let class-range (maxpop / bars)
      set-plot-pen-interval class-range
      let limite-basse 0
      let limite-haute (limite-basse + class-range)      
      repeat bars [
        let pop-ici count places with [(population > limite-basse) and (population <= limite-haute)]
        ; print (word limite-basse " " limite-haute " " pop-ici)
        plot pop-ici
        set limite-basse (limite-basse + class-range)
        set limite-haute (limite-haute + class-range)
      ]
  
  
end

to-report area-of-equality-triangle
  report (nbPlaces * (nbPlaces - 1) / 2) / (nbPlaces ^ 2) ;; formule g�n�rale pour la somme x+(x-1)+(x-2)+(x-3)+...+(x-x)?
 end

to return-home ; in case one would want to actually move the agents to the location of their city
  setxy [xcor] of mycity [ycor] of mycity
end


to extinction
  ask patch-at 40 50 [
    set plabel-color red
    set plabel "This society could not survive"]
  stop
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
223
61
751
610
-1
-1
5.18
1
10
1
1
1
0
1
1
1
0
99
0
99
0
0
1
ticks
30.0

BUTTON
7
81
70
114
NIL
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
77
81
140
114
NIL
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

BUTTON
146
81
209
114
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

SLIDER
9
159
212
192
growback
growback
0
2
2
0.01
1
NIL
HORIZONTAL

SLIDER
10
200
213
233
global-reach
global-reach
0
54
40
1
1
NIL
HORIZONTAL

PLOT
759
10
1054
151
Lorenz Curve City Sizes
Cities (%)
Pops (%)
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"lorenz" 1.0 0 -11221820 false "" ""
"equality" 100.0 0 -5825686 false "" ""

PLOT
761
158
1053
301
Gini Index City Sizes
Time
Gini Index
0.0
10.0
0.0
1.1
true
false
"" ""
PENS
"Gini Index" 1.0 0 -16777216 true "" ""

SLIDER
10
237
213
270
specialist-effect
specialist-effect
0
400
400
1
1
NIL
HORIZONTAL

PLOT
762
306
1054
446
Agents
time
nb. agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Specialists" 1.0 0 -2674135 true "" ""
"Peasants" 1.0 0 -10899396 true "" ""

PLOT
12
301
217
447
City Sizes
city sizes
nb. of cities
0.0
5.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
10
461
217
612
Number of Cities
time
nb. of cities
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" ""

CHOOSER
6
10
750
55
presets
presets
"manual" [["1. fertile land long reach"] [2 40 400]] [["2. fertile land short reach"] [2 2 400]] [["extinction limit"] [1.14 0 0]] [["3. ext. limit but relatively prosperous cities"] [1.14 10 200]] [["saved by cities I."] [0.95 3 400]] [["4. saved by cities II."] [0.7 10 400]] [["parasitic cities"] [2 50 0]] [["low reach in arid land"] [0.8 2 400]]
1

PLOT
763
451
1055
611
% urban population
time
proportion
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" ""

@#$#@#$#@
## WHAT IS IT?

The very existence of urban formations on all inhabited continents and throughout the history of mankind since the 3rd millennium B.C. leads to suppose a tendency of some structured societies to maximize interaction by minimizing physical distance. Were this tendency unconstrained, it should eventually lead to the concentration of all of the society's population into one single point: a situation only partially realized by the distribution of urban populations at the global scale. Models of constraints preventing its realization have thus to be proposed. We have set up one such model, using agent based simulation of food production and accessibility, in order to account for the structural constraints particular to the physical space. The simulations have notably shown that, while necessarily emerging from a society investing agricultural surplus into the

## HOW IT WORKS,  HOW TO USE IT, THINGS TO NOTICE, THINGS TO TRY

See online documentation at http://www.ourednik.info/urbanization_mc

## EXTENDING THE MODEL

Any extension suggestions will be apretiated. For contact information, see http://www.ourednik.info/urbanization_mc
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

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

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

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
