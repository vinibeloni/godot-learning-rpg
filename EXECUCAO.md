# Plano de Execucao - Reimplementacao Engine-Agnostic

## Visao Geral

Este plano descreve como reimplementar o jogo descrito no GDD em qualquer engine. Cada fase e independente e testavel. A ordem prioriza fundacoes antes de features.

**Principio:** Sempre que possivel, implemente sistemas como componentes reutilizaveis (como o projeto original faz com Movement, Stats, Hitbox, etc).

---

## Fase 0: Setup do Projeto

### 0.1 Configuracao basica
- [ ] Criar projeto com resolucao interna 320x180
- [ ] Configurar escala de janela para ~4x (1280x720)
- [ ] Configurar stretch/scale com aspect ratio "keep" (letterboxing se necessario)
- [ ] Definir layers/masks de fisica:
  - Layer 1: World
  - Layer 2: Player
  - Layer 3: PlayerHurtbox
  - Layer 4: EnemyHurtbox
  - Layer 5: Enemy
  - Layer 6: SoftCollisions
- [ ] Configurar acoes de input:
  - move_left, move_right, move_up, move_down (WASD/Setas/D-pad)
  - attack (Espaco/Q/Botao gamepad)
  - roll (E/Botao gamepad)

### 0.2 Organizacao de pastas
```
/raiz
  /Components/       (sistemas reutilizaveis: Stats, Hitbox, Hurtbox, SoftCollision, etc)
  /Player/
  /Enemies/
  /Effects/
  /UI/
  /World/
  /Shaders/
```

### 0.3 Importar assets
- [ ] Sprites do jogador (spritesheet 60 frames horizontal)
- [ ] Sprites do bat (5 frames animacao "Fly")
- [ ] Sprites de sombras, arvores, arbustos, grama
- [ ] Tilesets (dirt path 16x16, cliff 32x32)
- [ ] Background de grama
- [ ] SFX: swipe (ataque), evade (roll), hurt (dano jogador)
- [ ] Sprite de coracao (cheio e vazio) para HUD

---

## Fase 1: Sistemas Fundamentais (Componentes)

Cada componente e um sistema independente e testavel isoladamente.

### 1.1 Stats (Componente de Vida)
**Arquivo:** `Components/Stats`

**O que implementar:**
```
Classe Stats:
    max_health: int (configuravel, default=1)
    health: int (inicia=max_health)
    
    sinais:
        health_changed(valor: int)
        max_health_changed(valor: int)
        no_health()
    
    setter set_max_health(valor):
        max_health = valor
        health = min(health, max_health)
        emitir max_health_changed(max_health)
    
    setter set_health(valor):
        health = valor
        emitir health_changed(health)
        se health <= 0: emitir no_health()
    
    ao_iniciar:
        health = max_health
```

**Teste:** Criar entidade com Stats, causar dano, verificar sinais e morte.

### 1.2 Hitbox (Componente de Dano)
**Arquivo:** `Components/Hitbox`

**O que implementar:**
```
Classe Hitbox (Area de colisao):
    damage: int = 1
    layer: EnemyHurtbox (para SwordHitbox) ou PlayerHurtbox (para inimigos)
```

**Variante SwordHitbox:**
```
Classe SwordHitbox extends Hitbox:
    knockbackVector: Vector2 = ZERO
```

### 1.3 Hurtbox (Componente de Receber Dano)
**Arquivo:** `Components/Hurtbox`

**O que implementar:**
```
Classe Hurtbox (Area de colisao):
    invincible: bool = false
    timer: Timer
    
    sinais:
        invincibility_started()
        invincibility_ended()
    
    setter set_invincible(valor):
        invincible = valor
        se invincible: emitir invincibility_started()
        senao: emitir invincibility_ended()
    
    funcao start_invincibility(duracao):
        invincible = true
        timer.iniciar(duracao)
    
    funcao create_hit_effect():
        instanciar HitEffect na posicao global
        adicionar como filho da cena atual
    
    ao_timer_timeout:
        invincible = false  // usar setter para emitir sinal
    
    // Quando invincibilidade comeca:
    //   desabilitar collision shape (deferred)
    // Quando invincibilidade termina:
    //   reabilitar collision shape
```

**Teste:** Entidade A com Hitbox colide com entidade B com Hurtbox. Verificar dano, invincibilidade e efeito.

### 1.4 SoftCollision (Componente de Colisao Suave)
**Arquivo:** `Components/SoftCollision`

**O que implementar:**
```
Classe SoftCollision (Area de colisao, layer=SoftCollisions):
    
    funcao is_colliding() -> bool:
        return areas_sobrepostas.tamanho > 0
    
    funcao get_push_vector() -> Vector2:
        se is_colliding():
            direcao = areas[0].pos_global.direcao_para(pos_global)
            return direcao.normalizado()
        return Vector2.ZERO
```

### 1.5 PlayerDetectionZone (Componente de Deteccao)
**Arquivo:** `Components/PlayerDetectionZone`

**O que implementar:**
```
Classe PlayerDetectionZone (Area de colisao):
    player: referencia = null
    
    funcao can_see_player() -> bool:
        return player != null
    
    // on_body_entered (filtrar por Player layer):
    //   player = body
    // on_body_exited (filtrar por Player layer):
    //   player = null
```

**Teste:** Jogador entra/sai da area. Verificar can_see_player().

### 1.6 WanderController (Componente de Vagar)
**Arquivo:** `Components/WanderController`

**O que implementar:**
```
Classe WanderController (Node2D):
    wander_range: int = 32
    start_position: Vector2  (posicao de spawn)
    target_position: Vector2  (posicao alvo)
    timer: Timer
    
    ao_iniciar:
        start_position = pos_global
        target_position = pos_global
        update_target_position()
    
    funcao update_target_position():
        offset = Vector2(aleatorio(-wander_range, wander_range), aleatorio(-wander_range, wander_range))
        target_position = start_position + offset
    
    funcao get_time_left() -> float:
        return timer.tempo_restante
    
    funcao start_wander_timer(duracao):
        timer.iniciar(duracao)
    
    // on_timer_timeout:
    //   update_target_position()
```

### 1.7 Effect (Componente de Efeito Visual)
**Arquivo:** `Components/Effect`

**O que implementar:**
```
Classe Effect (Sprite Animado):
    ao_iniciar:
        conectar sinal "animacao_finalizada" -> _on_animation_finished
        tocar("Animate")
    
    funcao _on_animation_finished():
        destruir_si_mesmo(queue_free)
```

Criar cenas especificas:
- [ ] HitEffect (com animacao de impacto)
- [ ] GrassEffect (com animacao de grama cortada)
- [ ] EnemyDeathEffect (com animacao de morte)

### 1.8 Movement (Componente de Movimento)
**Arquivo:** `Components/Movement`

**O que implementar:**
```
Classe Movement (Node):
    ACCELERATION: int
    MAX_SPEED: int
    FRICTION: int
    ROLL_SPEED: int
    ROLL_FRICTION: int  // calculado = MAX_SPEED / 2
    
    looking_position: Vector2 = DOWN
    _velocity: Vector2 = ZERO
    parent_entity: referencia ao corpo fisico
    
    funcao setup(parent, acceleration, max_speed, friction, roll_speed):
        parent_entity = parent
        ACCELERATION = acceleration
        MAX_SPEED = max_speed
        FRICTION = friction
        ROLL_SPEED = roll_speed
        ROLL_FRICTION = MAX_SPEED / 2
    
    funcao apply_roll_acceleration():
        _velocity = looking_position * ROLL_SPEED
    
    funcao apply_roll_friction():
        _velocity = looking_position * ROLL_FRICTION
    
    funcao reset_velocity():
        _velocity = ZERO
    
    funcao move_player():
        _velocity = parent_entity.move_and_slide(_velocity)
    
    funcao apply_run_acceleration(input, delta):
        _velocity = _velocity.move_toward(input * MAX_SPEED, ACCELERATION * delta)
    
    funcao apply_run_friction(delta):
        _velocity = _velocity.move_toward(ZERO, FRICTION * delta)
```

### 1.9 MovementAnimation (Componente de Animacao)
**Arquivo:** `Components/MovementAnimation`

**O que implementar:**
```
Classe MovementAnimation (Node):
    animation_tree: referencia
    animation_state: referencia ao playback
    
    constantes: IDLE="Idle", RUN="Run", ROLL="Roll", ATTACK="Attack"
    
    funcao setup(tree):
        animation_tree = tree
        animation_tree.ativo = true
        animation_state = animation_tree.obter("parameters/playback")
    
    funcao idle():
        animation_state.travel(IDLE)
    
    funcao run():
        animation_state.travel(RUN)
    
    funcao roll():
        animation_state.travel(ROLL)
    
    funcao attack():
        animation_state.travel(ATTACK)
    
    funcao set_animations_position(direcao):
        para cada estado em [IDLE, RUN, ROLL, ATTACK]:
            animation_tree.set("parameters/{estado}/blend_position", direcao)
```

---

## Fase 2: Jogador

### 2.1 Cena do Jogador - Noclass/Estrutura
```
Player (Corpo Fisico 2D, layer=Player)
  Shadow (Sprite)
  Sprite (Sprite, 60 hframes, com material de blink)
  CollisionShape2D (Capsula: radius=4, height=3.5)
  AnimationPlayer
  AnimationTree (StateMachine com BlendSpace2D por direcao)
  HitboxPivot (Position2D, rotaciona com ataque)
    SwordHitbox (Hitbox, mask=EnemyHurtbox, damage=1)
      CollisionShape2D (Capsula: height=12)
  Hurtbox (Hurtbox, layer=PlayerHurtbox)
    CollisionShape2D (Capsula: radius=6, height=8, offset y=-5)
  AudioStreamPlayer (para SFX de ataque e roll)
  BlinkAnimation (AnimationPlayer: Start, Stop, RESET)
  Movement (Node, script Movement)
  MovementAnimation (Node, script MovementAnimation)
```

### 2.2 Script do Jogador
Implementar state machine:
```
enum Estado { MOVE, ROLL, ATTACK }
var estado = MOVE
var stats = PlayerStats (singleton)

ao_iniciar:
    conectar stats.no_health -> destruir_si_mesmo
    swordHitbox.knockbackVector = movement.looking_position
    movement.setup(self, 500, 100, 500, 120)
    animation.setup(animationTree)

a_cada_frame_fisico(delta):
    match estado:
        MOVE: _move_state(delta)
        ROLL: _roll_state()
        ATTACK: _attack_state()

funcao _move_state(delta):
    input = obter_input_jogador()
    se input == ZERO:
        _parar(delta)
    senao:
        _mover(input, delta)
    movement.move_player()
    _verificar_novo_estado()

funcao _obter_input_jogador():
    input.x = forca_direita - forca_esquerda
    input.y = forca_baixo - forca_cima
    return input.normalizado()

funcao _mover(input, delta):
    movement.looking_position = input
    swordHitbox.knockbackVector = input
    animation.set_animations_position(input)
    animation.run()
    movement.apply_run_acceleration(input, delta)

funcao _parar(delta):
    animation.idle()
    movement.apply_run_friction(delta)

funcao _verificar_novo_estado():
    se pressionou("roll"): estado = ROLL
    se pressionou("attack"): estado = ATTACK

funcao _roll_state():
    movement.apply_roll_acceleration()
    animation.roll()
    movement.move_player()

funcao _attack_state():
    movement.reset_velocity()
    animation.attack()

// Callbacks de animacao:
funcao roll_animation_finished():
    movement.apply_roll_friction()
    estado = MOVE

funcao attack_animation_finished():
    estado = MOVE

// Sinais de dano:
funcao on_hurtbox_area_entered(area):
    stats.health -= area.damage
    hurtbox.start_invincibility(0.8)
    hurtbox.create_hit_effect()
    // Spawnar som de hurt

funcao on_hurtbox_invincibility_started():
    blinkAnimation.tocar("Start")

funcao on_hurtbox_invincibility_ended():
    blinkAnimation.tocar("Stop")
```

### 2.3 Animation Tree (Maquina de States de Animacao)
Configurar tree com:
- 4 BlendSpace2D (Idle, Run, Roll, Attack) com 4 direcoes cada
- StateMachine: Idle <-> Run, Idle -> Attack -> Idle, Idle -> Roll -> Idle
- Blend positions: Left=(-1,0), Right=(1,0), Up=(0,-1), Down=(0,1)

### 2.4 Blink Shader
```
se active: cor = branco (preserva alpha)
senao: cor = cor original
```

**Teste:** Movimentar jogador, atacar, rolar. Verificar transicoes e hitbox ativacao/desativacao.

---

## Fase 3: HUD e Menu

### 3.1 PlayerStats (Singleton/Autoload)
```
Classe PlayerStats:
    herda ou instancia Stats com max_health = 4
```

### 3.2 HealthUI
```
HealthUI (Control/UI)
    +-- HeartUIFull (imagem de coracoes cheios, largura = coracoes * 15px)
    +-- HeartUIEmpty (imagem de coracoes vazios, largura = max_coracoes * 15px)

ao_iniciar:
    max_hearts = PlayerStats.max_health
    hearts = PlayerStats.health
    conectar PlayerStats.health_changed -> set_hearts
    conectar PlayerStats.max_health_changed -> set_max_hearts
```

**Teste:** Causar dano ao jogador. Verificar coracoes diminuindo. Curar. Verificar coracoes aumentando.

### 3.3 Menu Principal
```
Menu (Control)
    +-- VBoxContainer
          +-- Botao "Start"
          +-- Botao "Quit"

ao_iniciar: "Start" recebe foco
ao_clicar_start: carregar cena "World"
ao_clicar_quit: fechar jogo
```

---

## Fase 4: Inimigo (Bat)

### 4.1 Estrutura do Bat
```
Bat (Corpo Fisico 2D, layer=Enemy)
  AnimatedSprite (anim "Fly", 5 frames, loop)
  Shadow (Sprite)
  CollisionShape2D (Circulo, radius=3.16)
  Hurtbox (Hurtbox, layer=EnemyHurtbox)
    CollisionShape2D (Capsula, radius=6, height=6, offset y=-13)
  Stats (max_health=3)
  PlayerDetectionZone (Area, circulo radius=83, detecta Player)
    CollisionShape2D
  Hitbox (Hitbox, mask=PlayerHurtbox, damage=2)
    CollisionShape2D (Circulo, radius=3, offset y=-13)
  SoftCollision (SoftCollision)
    CollisionShape2D (Circulo, radius=3)
  WanderController (wander_range=32)
  BlinkAnimation (AnimationPlayer: Start, Stop, RESET)
```

### 4.2 Script do Bat
```
Constantes: ACCELERATION=300, MAX_SPEED=50, FRICTION=200, KNOCKBACK=130, COLLISION_PUSH=400
enum Estado { IDLE, WANDER, CHASE }
var estado = IDLE ou WANDER (aleatorio ao iniciar)
var velocidade = ZERO
var knockback = ZERO

a_cada_frame_fisico(delta):
    // Knockback com friccao
    knockback = knockback.mover_toward(ZERO, FRICTION * delta)
    knockback = mover_e_deslizar(knockback)
    
    match estado:
        IDLE:
            velocidade = velocidade.mover_toward(ZERO, ACCELERATION * delta)
            procurar_jogador()
            verificar_novo_estado()
        WANDER:
            procurar_jogador()
            verificar_novo_estado()
            acelerar_para_ponto(wanderController.target_position, delta)
            se posicion_proxima_do_alvo(): verificar_novo_estado()
        CHASE:
            se playerDetectionZone.can_see_player():
                acelerar_para_ponto(jogador.pos_global, delta)
            senao:
                estado = IDLE
    
    se softCollision.is_colliding():
        velocidade += softCollision.get_push_vector() * delta * COLLISION_PUSH
    
    velocidade = mover_e_deslizar(velocidade)

funcao procurar_jogador():
    se playerDetectionZone.can_see_player():
        estado = CHASE

funcao acelerar_para_ponto(ponto, delta):
    direcao = pos_global.direcao_para(ponto)
    velocidade = velocidade.mover_toward(direcao * MAX_SPEED, ACCELERATION * delta)
    sprite.flip_h = velocidade.x < 0

funcao verificar_novo_estado():
    se wanderController.get_time_left() == 0:
        estado = escolher_aleatorio([IDLE, WANDER])
        wanderController.start_wander_timer(aleatorio(1, 3))

funcao escolher_aleatorio(lista):
    lista.embaralhar()
    return lista.pop_primeiro()

// Dano e morte:
funcao on_hurtbox_area_entered(area):
    stats.health -= area.damage
    knockback = area.knockbackVector * KNOCKBACK
    hurtbox.create_hit_effect()
    hurtbox.start_invincibility(0.4)

funcao on_stats_no_health():
    destruir_si_mesmo
    instanciar EnemyDeathEffect na pos_global

funcao on_hurtbox_invincibility_started():
    blinkAnimation.tocar("Start")

funcao on_hurtbox_invincibility_ended():
    blinkAnimation.tocar("Stop")
```

**Teste:** Bat vagueia, detecta jogador, persegue, recebe dano, morre com efeito.

---

## Fase 5: Mundo e Ambiente

### 5.1 Tilemaps
- [ ] Configurar tileset de dirt path (16x16, autotile com bitmask)
- [ ] Configurar tileset de cliff (32x32, com colisao)
- [ ] Montar mapa com background, paths e cliffs
- [ ] Certificar que cliffs tem colisao na layer World

### 5.2 Estrutura da Cena World
```
World (no que ordena filhos por Y)
  Background (TextureRect)
  DirtPathTileMap
  DirtCliffTileMap
  Camera2D
    Limits/TopLeft
    Limits/BottomRight
  YSort
    Player
      RemoteTransform2D -> Camera2D
    Bushes (YSort)
    Grasses (YSort)
    Bats (YSort)
    Trees (YSort)
  CanvasLayer
    HealthUI
```

**YSort**: Sistema que ordena renderizacao por posicao Y (profundidade/top-down).

### 5.3 Camera
```
Camera2D:
    ao_iniciar:
        limite_cima = topLeft.y
        limite_esquerda = topLeft.x
        limite_baixo = bottomRight.y
        limite_direita = bottomRight.x

RemoteTransform2D no Player:
    remote_path = Camera2D
    (faz camera seguir jogador suavemente)
```

### 5.4 Grass (Destrutivel)
```
Grass (Node2D):
    +-- AnimatedSprite (animacao de grama)
    +-- Hurtbox (Area2D, qualquer layer de hitbox detecta)
    +-- Area2D (para colisao)

funcao on_hurtbox_area_entered(area):
    criar_efeito(GrassEffect)
    destruir_si_mesmo
```

### 5.5 Tree e Bush (Obstaculos estaticos)
- Arvores e arbustos com CollisionShape2D na layer World
- Ordenados por Y via YSort

**Teste:** Caminhar pelo mapa, interagir com grama (destruir), colidir com arvores e cliffs.

---

## Fase 6: Integracao e Polish

### 6.1 Conectar tudo
- [ ] Player spawna no World
- [ ] Camera segue Player
- [ ] HealthUI reflete PlayerStats
- [ ] Menu -> World transicao funciona
- [ ] Bats no mapa perseguem Player
- [ ] Player pode atacar Bats
- [ ] Bats podem ferir Player
- [ ] Invincibilidade + blink funciona para ambos
- [ ] Efeitos visuais spawnam corretamente
- [ ] Soft collision entre Bats funciona
- [ ] Grass e destrutivel

### 6.2 SFX
- [ ] Swipe sound ao atacar (acionado na animacao)
- [ ] Evade sound ao rolar (acionado na animacao)
- [ ] Hurt sound ao receber dano (PlayerHurtSound)

### 6.3 Teste Final (Checklist)
- [ ] Jogador move em 4 direcoes com aceleracao/friccao
- [ ] Jogador rola na direcao que esta olhando
- [ ] Jogador ataca na direcao que esta olhando
- [ ] Hitbox da espada so ativa durante a janela de ataque
- [ ] Knockback funciona em ambas direcoes
- [ ] Invincibilidade de 0.8s jogador, 0.4s inimigo
- [ ] Blink visual durante invincibilidade
- [ ] Bats alternam entre IDLE/WANDER/CHASE
- [ ] Bats detectam jogador e perseguem
- [ ] Bats perdem jogador e voltam a vagar
- [ ] Bat morre apos 3 hits com efeito de morte
- [ ] Player morre apos 4 hits (queue_free, sem game over)
- [ ] Soft collision impede Bats de se sobrepor
- [ ] Grass e destruida ao contato com hitbox
- [ ] HealthUI atualiza corretamente
- [ ] Camera fica dentro dos limites do mapa
- [ ] Menu inicia e carrega World corretamente

---

## Fase 7: Expansoes (Opcional)

Ver secao 7 do GDD para ideias de expansao. Implementacao sugerida em ordem de prioridade:

1. **Game Over/Respawn** - Tela ao morrer, respawn
2. **Mais inimigos** - Reusar arquitetura de Bat
3. **Pickups (coracoes)** - Area2D com body_entered
4. **Transicao de salas** - Zonas que carregam novas cenas
5. **Inventario** - Sistema de items equipaveis
6. **Boss** - State machine mais complexa com phases