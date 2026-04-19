# Game Design Document (GDD)
# godor-learning-RPG

---

## 1. Visao Geral

**Nome:** godor-learning-RPG
**Genero:** Action RPG 2D top-down
**Resolucao interna:** 320x180 (pixel art, escala para 1280x720)
**Categoria:** Projeto de aprendizado de mecânicas de RPG

O jogador controla um personagem que explora um cenario top-down com inimigos (bats). O jogo possui movimento 4-direcoes, ataque com espada, rolagem (roll/dodge) com invincibilidade, sistema de stats/vida, e IA basica de inimigos com estados (idle, wander, chase).

---

## 2. Fluxo do Jogo

```
[Menu Principal] -> "Start" -> [World (gameplay)] -> Morreu -> Destroi jogador
                                  ^                      |
                                  |--- Bats no mapa ------|
```

- Menu simples com botoes "Start" e "Quit"
- Nao existe tela de game over; ao morrer, o Player e destruido (queue_free)

---

## 3. Sistemas Core

### 3.1 Sistema de Movimento

**Componente:** `Movement` (reutilizavel, acoplavel a qualquer entidade)

**Parametros configuraveis:**
| Parametro | Tipo | Descricao |
|---|---|---|
| acceleration | int | Aceleracao durante corrida |
| max_speed | int | Velocidade maxima de corrida |
| friction | int | Desaceleracao ao soltar input |
| roll_speed | int | Velocidade durante roll (equivale a ~2.4x a velocidade de friccao do roll) |

**Logica (pseudo-codigo generico):**
```
funcao apply_run_acceleration(input, delta):
    velocidade = mover_toward(velocidade, input * max_speed, acceleration * delta)

funcao apply_run_friction(delta):
    velocidade = mover_toward(velocidade, Vector2.ZERO, friction * delta)

funcao apply_roll_acceleration():
    velocidade = direcao_olhando * roll_speed

funcao apply_roll_friction():
    velocidade = direcao_olhando * (max_speed / 2)

funcao move_player():
    velocidade = mover_e_deslizar(velocidade)  // resolve colisao com world
    return velocidade
```

**Valores de referencia (jogador):**
- acceleration: 500, max_speed: 100, friction: 500, roll_speed: 120

### 3.2 Sistema de Animacao

**Componente:** `MovementAnimation` (reutilizavel, acoplavel a qualquer entidade com AnimationTree)

**Descricoes de estado:**
| Estado | Blend Position | Animacao |
|---|---|---|
| Idle | Direcao (Vector2) | Pose parado na direcao |
| Run | Direcao (Vector2) | Ciclo de corrida 4-dir (6 frames, 0.6s loop) |
| Roll | Direcao (Vector2) | Animacao de roll 4-dir (5 frames, 0.5s, NAO loop) |
| Attack | Direcao (Vector2) | Animacao de ataque 4-dir (4 frames, 0.4s, NAO loop) |

A maquina de estados de animacao segue este fluxo:
```
Idle <-> Run
Idle -> Attack -> Idle (ao termino da animacao)
Idle -> Roll -> Idle (ao termino da animacao)
```

**Pseudo-codigo:**
```
funcao setup(animation_tree):
    animation_tree.ativo = true
    playback = animation_tree.obter("parameters/playback")

funcao idle():
    playback.transitar_para("Idle")

funcao run():
    playback.transitar_para("Run")

funcao roll():
    playback.transitar_para("Roll")

funcao attack():
    playback.transitar_para("Attack")

funcao set_animations_position(direcao):
    para cada estado em [Idle, Run, Roll, Attack]:
        animation_tree.definir("parameters/{estado}/blend_position", direcao)
```

### 3.3 State Machine do Jogador

O jogador opera com uma **state machine simples por enum** com tres estados:

```
enum State { MOVE, ROLL, ATTACK }
```

**Estado MOVE:**
- Le input do jogador
- Se input != ZERO: aplica aceleracao + animacao run
- Se input == ZERO: aplica friccao + animacao idle
- Move o jogador (resolve colisao com mundo)
- Ao pressionar "roll" -> transita para ROLL
- Ao pressionar "attack" -> transita para ATTACK
- Atualiza direcao de olhar (looking_position) e knockbackVector da espada

**Estado ROLL:**
- Aplica velocidade fixa na direcao atual (roll_speed)
- Toca animacao de roll
- Move o jogador
- Ao termino da animacao: aplica friccao residual e volta para MOVE

**Estado ATTACK:**
- Zera velocidade
- Toca animacao de ataque
- Ativa/desativa hitbox da espada via animacao (frames especificos)
- Ao termino da animacao: volta para MOVE

**Diagrama de transicao:**
```
MOVE --[press roll]--> ROLL --[anim finish]--> MOVE
MOVE --[press attack]--> ATTACK --[anim finish]--> MOVE
```

**Input mapeado:**
| Acao | Teclas |
|---|---|
| Mover (4 direcoes) | WASD / Setas / D-pad |
| Attack | Espaco / Q / Botao gamepad |
| Roll | E / Botao gamepad |

### 3.4 Sistema de Combate (Hitbox / Hurtbox)

Este e o sistema central de dano. Baseado em **areas de colisao** com camadas (layers/masks).

**Arquitetura:**

```
Hitbox (causa dano)           Hurtbox (recebe dano)
- damage: int                 - invincible: bool
- knockbackVector: Vector2    - Timer (invincibilidade)
  (so SwordHitbox tem)        - CollisionShape (desabilita durante invinc.)
                               - sinal: invincibility_started
                               - sinal: invincibility_ended
```

**Camadas de colisao (physics layers):**
| Layer | Nome | Uso |
|---|---|---|
| 1 | World | Colisao com terreno/fixtures |
| 2 | Player | Corpo do jogador |
| 3 | PlayerHurtbox | Hurtbox do jogador |
| 4 | EnemyHurtbox | Hurtbox dos inimigos |
| 5 | Enemy | Corpo dos inimigos |
| 6 | SoftCollisions | Colisao suave entre entidades |

**Regras de colisao:**
- Player Hitbox (SwordHitbox): mascara = EnemyHurtbox (layer 4)
- Player Hurtbox: layer = PlayerHurtbox (layer 3)
- Enemy Hitbox: mascara = PlayerHurtbox (layer 3)
- Enemy Hurtbox: layer = EnemyHurtbox (layer 4)

**Fluxo de dano:**
```
1. Hitbox de A entra em colisao com Hurtbox de B
2. B.health -= A.damage
3. B aplica knockback: velocidade_knockback = A.knockbackVector * KNOCKBACK_FORCE
4. Hurtbox de B cria efeito visual de hit
5. Hurtbox de B inicia invincibilidade (0.4s inimigos, 0.8s jogador)
6. Durante invincibilidade, collision shape da Hurtbox e desabilitado
7. Visual: sprite pisca (blink) usando shader de cor branca
```

**SwordHitbox (extensao de Hitbox):**
- Adiciona `knockbackVector` que e setado para a direcao de olhar do jogador
- O HitboxPivot (Position2D) rotaciona junto com a direcao do ataque na animacao

### 3.5 Sistema de Stats (Vida)

**Componente:** `Stats`

**Propriedades:**
```
max_health: int (export, default = 1)
health: int (inicia = max_health)
```

**Sinais:**
- `health_changed(valor)` - emitido sempre que health muda
- `max_health_changed(valor)` - emitido quando max_health muda
- `no_health` - emitido quando health <= 0

**Logica:**
```
setter set_max_health(valor):
    max_health = valor
    health = min(health, max_health)
    emitir max_health_changed(max_health)

setter set_health(valor):
    health = valor
    emitir health_changed(health)
    se health <= 0:
        emitir no_health
```

**Valores de referencia:**
- Jogador: max_health = 4
- Bat: max_health = 3

**PlayerStats** e um Singleton (autoload) que instancia Stats com max_health = 4.

### 3.6 Sistema de Inimigo (Bat)

**IA por State Machine com tres estados:**

```
enum State { IDLE, WANDER, CHASE }
```

**Parametros configuraveis (Bat):**
| Parametro | Valor | Descricao |
|---|---|---|
| ACCELERATION | 300 | Aceleracao em direcao ao alvo |
| MAX_SPEED | 50 | Velocidade maxima |
| FRICTION | 200 | Desaceleracao |
| KNOCKBACK | 130 | Forca de knockback ao ser atingido |
| COLLISION_PUSH | 400 | Forca de empurrao suave |

**Estado IDLE:**
- Desacelera ate parar
- Verifica se jogador esta na zona de deteccao -> CHASE
- Quando o timer do WanderController expira, sorteia novo estado (IDLE ou WANDER)

**Estado WANDER:**
- Move-se em direcao a uma posicao alvo aleatoria (dentro de wanderRange)
- Verifica se jogador esta na zona de deteccao -> CHASE
- Quando chega proximo ao alvo ou timer expira, sorteia novo estado

**Estado CHASE:**
- Move-se em direcao ao jogador
- Se jogador sai da zona de deteccao -> IDLE

**Pseudo-codigo:**
```
funcao _physics_process(delta):
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
            acelerar_para_ponto(wanderController.posAlvo, delta)
            se perto_do_alvo: verificar_novo_estado()

        CHASE:
            se zonaDeteccao.pode_ver_jogador():
                acelerar_para_ponto(jogador.posGlobal, delta)
            senao:
                estado = IDLE

    // Soft collision (empurrar outros inimigos)
    se softCollision.esta_colidindo():
        velocidade += softCollision.vetor_empurrao() * delta * COLLISION_PUSH

    velocidade = mover_e_deslizar(velocidade)
```

**WanderController:**
```
wanderRange: int = 32  // distancia maxima do ponto de origem
posInicio = posGlobal
posAlvo = posGlobal

funcao atualizar_pos_alvo():
    offset_aleatorio = Vector2(aleatorio(-wanderRange, wanderRange), aleatorio(-wanderRange, wanderRange))
    posAlvo = posInicio + offset_aleatorio

funcao iniciar_timer_wander(duracao):
    timer.iniciar(duracao)  // tipicamente 1-3 segundos

// Timer expira -> atualizar_pos_alvo()
```

**PlayerDetectionZone:**
```
jogador: referencia = null

funcao pode_ver_jogador():
    return jogador != null

// on_body_entered -> jogador = body
// on_body_exited -> jogador = null
```

**Ao morrer (no_health):**
```
1. Destroi a entidade (queue_free)
2. Spawna efeito de morte no local
```

### 3.7 Sistema de Invencibilidade e Blink

**Fluxo:**
```
1. Hurtbox.area_entered (Hitbox entrou)
2. stats.health -= hitbox.damage
3. hurtbox.iniciar_invencibilidade(duracao)
4. hurtbox.criar_efeito_hit()           // spawna efeito visual
5. Emitir sinal "invincibility_started"
6. -> BlinkAnimation.play("Start")       // sprite pisca branco
7. -> CollisionShape.desabilitado = true  // nao recebe mais hits

// Timer expira:
8. Emitir sinal "invincibility_ended"
9. -> BlinkAnimation.play("Stop")         // sprite para de piscar
10. -> CollisionShape.desabilitado = false // pode receber hits novamente
```

**Blink Animation:**
- "Start": Loop de 0.2s, alterna shader_param `active` entre true/false
- "Stop": 0.1s, seta shader_param `active` = false

**Shader de blink (whiteColor):**
```
se active == true:
    cor = branco (mantendo alpha original)
senao:
    cor = cor_original
```

### 3.8 Soft Collision

Evita que entidades dobre sobre si mesmas, empurrando-as suavemente.

```
funcao esta_colidindo():
    return areas_sobrepostas.tamanho > 0

funcao vetor_empurrao():
    se esta_colidindo():
        direcao = areas[0].posGlobal.direcao_para(posGlobal)
        return direcao.normalizado()
    return Vector2.ZERO
```

A forca e aplicada multiplicada por `COLLISION_PUSH * delta`.

### 3.9 Efeitos Visuais

Todos os efeitos seguem o mesmo padrao:
```
1. Instanciar cena de efeito
2. Setar posGlobal
3. Adicionar como filho da cena atual
4. Animacao toca automaticamente
5. Ao fim da animacao -> destruir (queue_free)
```

**Efeitos existentes:**
| Efeito | Descricao |
|---|---|
| HitEffect | Efeito de impacto quando alguem e atingido |
| GrassEffect | Efeito de grama cortada (quando grama e destruida) |
| EnemyDeathEffect | Efeito de morte do inimigo |
| PlayerHurtSound | Sound effect que toca e se autodestroiz ao fim |

### 3.10 Camera

- Camera 2D que segue o jogador via RemoteTransform2D
- Possui limites configurados (topLeft, bottomRight)
- Resolucao interna 320x180

---

## 4. Estrutura de Cenas (Nodes)

### 4.1 Player (KinematicBody2D)
```
Player (KinematicBody2D, layer=Player)
  +-- Shadow (Sprite)
  +-- Sprite (Sprite, 60 hframes, com shader de blink)
  +-- CollisionShape2D (CapsuleShape: radius=4, height=3.5)
  +-- AnimationPlayer (anims: Idle*, Run*, Attack*, Roll*, 4 direcoes cada)
  +-- AnimationTree (StateMachine: Idle <-> Run, Idle -> Attack, Idle -> Roll)
  +-- HitboxPivot (Position2D, rotaciona com ataque)
  |     +-- SwordHitbox (Area2D, Hitbox, mask=EnemyHurtbox)
  |           +-- CollisionShape2D (CapsuleShape: height=12)
  +-- Hurtbox (Area2D, Hurtbox, layer=PlayerHurtbox)
  |     +-- CollisionShape2D (CapsuleShape: radius=6, height=8)
  +-- AudioStreamPlayer
  +-- BlinkAnimation (AnimationPlayer: Start, Stop, RESET)
  +-- Movement (Node, script Movement.gd)
  +-- MovementAnimation (Node, script MovementAnimation.gd)
```

**Nota sobre ataque:** A HitboxPivot rotaciona em relacao a direcao do ataque:
- Direita: 0 graus
- Baixo: 90 graus
- Esquerda: 180 graus
- Cima: -90 graus

A animacao de ataque ativa a CollisionShape2D do SwordHitbox nos frames 0.1s e desativa em 0.3s (duracao de 0.2s ativa).

### 4.2 Bat (KinematicBody2D)
```
Bat (KinematicBody2D, layer=Enemy)
  +-- AnimatedSprite (anim "Fly", 5 frames, loop)
  +-- Shadow (Sprite)
  +-- CollisionShape2D (Circle, radius=3.16)
  +-- Hurtbox (Area2D, layer=EnemyHurtbox)
  |     +-- CollisionShape2D (Capsule, radius=6, height=6)
  +-- Stats (Node, max_health=3)
  +-- PlayerDetectionZone (Area2D, circle radius=83, detecta Player layer)
  +-- Hitbox (Area2D, mask=PlayerHurtbox, damage=2)
  |     +-- CollisionShape2D (Circle, radius=3)
  +-- SoftCollision (Area2D, layer=SoftCollisions)
  |     +-- CollisionShape2D (Circle, radius=3)
  +-- WanderController (Node2D, wanderRange=32)
  +-- BlinkAnimation (AnimationPlayer)
```

### 4.3 World (Node: YSort)
```
World (YSort)
  +-- Background (TextureRect, imagem de fundo)
  +-- DirtPathTileMap (TileMap, 16x16 tiles, autotile)
  +-- DirtCliffTileMap (TileMap, 32x32 tiles, com colisao)
  +-- Camera2D
  |     +-- Limits/
  |           +-- TopLeft (Position2D)
  |           +-- BottomRight (Position2D)
  +-- YSort
  |     +-- Player
  |     +-- RemoteTransform2D -> Camera2D
  |     +-- Bushes (YSort)
  |     +-- Grasses (YSort)
  |     +-- Bats (YSort)
  |     +-- Trees (YSort)
  +-- CanvasLayer
        +-- HealthUI
```

### 4.4 Grass (Node2D - destrutivel)
```
Grass (Node2D)
  +-- Hurtbox (Area2D)
  +-- Area2D (collider para deteccao)
  +-- AnimatedSprite (animacao de grama)
```
Quando qualquer hitbox/area entra: spawna GrassEffect e se destroi.

### 4.5 HealthUI (Control)
```
HealthUI (Control)
  +-- HeartUIFull (TextureRect, largura = coracoes * 15px)
  +-- HeartUIEmpty (TextureRect, largura = max_coracoes * 15px)
```

Cada coracao tem 15px de largura. Conectado aos sinais `health_changed` e `max_health_changed` do PlayerStats.

### 4.6 Menu (Control)
```
Menu (Control)
  +-- VBoxContainer
        +-- Start (Button)
        +-- Quit (Button)
```

---

## 5. Singleton / Autoload

| Nome | Caminho | Descricao |
|---|---|---|
| PlayerStats | Player/PlayerStats.tscn | Stats com max_health=4, acessivel globalmente |

---

## 6. Organizacao de Arquivos

```
/raiz
  /Character Bahavior/     (comportamento reutilizavel)
    Movement.gd/tscn
    MovementAnimation.gd/tscn
  /Camera2D.gd/tscn
  /Effects/
    Effect.gd             (base: auto-destroi ao fim da anim)
    HitEffect.tscn
    GrassEffect.tscn
    EnemyDeathEffect.tscn
  /Enemies/
    Bat.gd/tscn
    WanderController.gd/tscn
  /Overlap/               (sistemas de colisao reutilizaveis)
    Hitbox.gd/tscn
    Hurtbox.gd/tscn
    SoftCollision.gd/tscn
    PlayerDetectionZone.gd/tscn
  /Player/
    Player/
      Player.gd/tscn      (state machine do jogador)
    SwordHitbox.gd         (extensao de Hitbox com knockback)
    Hurtsound/
      PlayerHurtSound.gd/tscn
    PlayerStats.tscn       (autoload)
  /Shadows/
  /UI/
    Menu.gd/tscn
    HealthUI.gd/tscn
  /World/
    Grass.gd/tscn
    Tree.tscn
    Bush.tscn
  Stats.gd/tscn           (componente de vida reutilizavel)
  World.tscn              (cena principal de gameplay)
  whiteColor.shader        (shader de blink)
```

---

## 7. Sugestoes de Expansao

Baseado na arquitetura existente, estas NAO estao implementadas mas sao extensoes naturais:

1. **Mais tipos de inimigo** - O sistema Bat com State Machine (IDLE/WANDER/CHASE), Stats e Hitbox/Hurtbox e completamente reutilizavel. Criar Frog, Skeleton, etc seguindo o mesmo padrao.

2. **Sistema de itens/pickups** - Coracoes de vida, moedas, etc. Implementar como area com body_entered.

3. **Transicao de cenas** - Portas/zonas que carregam novas cenas (Room-based dungeon).

4. **Sistema de inventario** - Armas, escudos, consumiveis.

5. **Boss fights** - Inimigos com phases e padroes de ataque mais complexos.

6. **Game Over / Respawn** - Em vez de queue_free, tela de game over e respawn.

7. **Save system** - Persistir stats, posicao e cenas visitadas.

8. **Sistema de dano variavel** - Armas diferentes causam dano diferente (hitbox.damage configuravel).

9. **Knockback direcional no inimigo** - Inimigo tb usa knockbackVector em vez de velocidade fixa.

10. **Dialogo/NPC** - Sistema de interacao com NPCs usando area de deteccao.

---

## 8. Detalhes Numericos de Referencia

### Jogador
| Propriedade | Valor |
|---|---|
| Max Health | 4 |
| Acceleration | 500 |
| Max Speed | 100 |
| Friction | 500 |
| Roll Speed | 120 |
| Roll Duration (anim) | 0.5s |
| Attack Duration (anim) | 0.4s |
| Invincibility Duration | 0.8s |
| Attack Hitbox Window | 0.1s ativo a 0.3s (0.2s de janela) |

### Bat
| Propriedade | Valor |
|---|---|
| Max Health | 3 |
| Hitbox Damage | 2 |
| Acceleration | 300 |
| Max Speed | 50 |
| Friction | 200 |
| Knockback Force | 130 |
| Soft Collision Push | 400 |
| Detection Range | 83 radius |
| Wander Range | 32 pixels |
| Wander Timer | 1-3s random |
| Invincibility | 0.4s |

### Camera / Resolucao
| Propriedade | Valor |
|---|---|
| Viewport | 320x180 |
| Test Window | 1280x720 |
| Stretch Mode | 2d / canvas_items |
| Stretch Aspect | keep |

### Animacoes do Jogador
| Grupo | Frames | Duracao | Loop |
|---|---|---|---|
| Idle (4 dir) | 1 frame cada | 0.1s | Nao |
| Run (4 dir) | 6 frames cada | 0.6s | Sim |
| Attack (4 dir) | 4 frames cada | 0.4s | Nao |
| Roll (4 dir) | 5 frames cada | 0.5s | Nao |

Sprite: 60 hframes (spritesheet horizontal)