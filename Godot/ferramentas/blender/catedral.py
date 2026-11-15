# Nave da catedral em ruínas (Fase 1 — Ruínas de Arvália), modelada no Blender.
# Roda com o Blender como módulo Python (pip install bpy) ou dentro do Blender:
#   python catedral.py previa  X1 X2 ...   -> renders de prévia na câmera do jogo (x em unidades)
#   python catedral.py camadas             -> renderiza as camadas e grava em Godot/assets/cenario/fase1/
# Eixos: Blender X = x do jogo, Blender Y = profundidade (Godot z = -Y), Blender Z = altura (Godot y).
# 1 unidade = 26 px do jogo no plano z = 0. Chão em Z = 0.
import bpy, bmesh, math, random, sys, os, json
from mathutils import Vector, Matrix

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "assets", "cenario", "fase1"))
random.seed(7)

BAIA = 8.0                     # distância entre pilares
PILARES = [-4.0 + BAIA * k for k in range(19)]   # -4 .. 140
X_MIN, X_MAX = -14.0, 150.0
Y_ARCADA = 5.0                 # parede da arcada (camada "perto")
Y_MURO = 14.0                  # parede externa com vitrais (camada "meio")
Y_LONGE = 60.0
ALT_IMPOSTA = 6.2              # onde o arco nasce
ROSA_X = 96.0                  # rosácea gigante atrás da arena do chefe
FOGOS = []                     # braseiros (x, y, z) para o Godot acender chamas vivas

# variações por baia (baia k fica entre PILARES[k] e PILARES[k+1])
PILAR_QUEBRADO = {4: 2.4, 10: 3.6}          # índice do pilar -> altura que sobrou
ARCO_QUEBRADO = {2, 9, 13}
MURO_CAIDO = {5, 12}
TETO_ABERTO = {1, 5, 6, 12, 15}
BRASEIROS = [1, 3, 6, 8, 11, 13, 15]        # pilares com braseiro na frente

COLECOES = ["perto", "meio", "longe", "chao", "borda", "plat", "frente", "aux"]

# ------------------------------------------------------------------ cena
def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for n in COLECOES:
        c = bpy.data.collections.new(n)
        sc.collection.children.link(c)
    return sc

def col(n):
    return bpy.data.collections[n]

def obj_de_bm(nome, bm, colecao, mat=None):
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(nome, me)
    col(colecao).objects.link(ob)
    if mat: me.materials.append(mat)
    return ob

def bevel(ob, w=0.04, seg=2, ang=40):
    m = ob.modifiers.new("bev", "BEVEL")
    m.width = w; m.segments = seg; m.limit_method = "ANGLE"; m.angle_limit = math.radians(ang)
    m.harden_normals = False
    return m

def suave(ob):
    for p in ob.data.polygons: p.use_smooth = True

# ------------------------------------------------------------------ materiais
def no(nt, tipo, x=0, y=0, **kw):
    n = nt.nodes.new(tipo); n.location = (x, y)
    for k, v in kw.items():
        setattr(n, k, v)
    return n

def rampa(nt, cores, x=0, y=0, interp="LINEAR"):
    r = no(nt, "ShaderNodeValToRGB", x, y)
    r.color_ramp.interpolation = interp
    els = r.color_ramp.elements
    while len(els) > 1: els.remove(els[-1])
    els[0].position = cores[0][0]; els[0].color = hexa(cores[0][1])
    for p, c in cores[1:]:
        e = els.new(p); e.color = hexa(c)
    return r

def hexa(h, a=1.0):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    c = [((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c]   # sRGB -> linear
    return (c[0], c[1], c[2], a)

def mat_pedra(nome, claro, escuro, escala=1.0, juntas=None, musgo=0.35, rug=0.9, plano="xz", brilho_borda=0.25):
    """Pedra pintada: manchas grandes, variação por bloco, juntas, sujeira e musgo nos cantos (AO), quinas gastas."""
    m = bpy.data.materials.new(nome); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear(); L = nt.links
    out = no(nt, "ShaderNodeOutputMaterial", 1400, 0)
    bsdf = no(nt, "ShaderNodeBsdfPrincipled", 1150, 0)
    bsdf.inputs["Roughness"].default_value = rug
    L.new(bsdf.outputs[0], out.inputs[0])
    geo = no(nt, "ShaderNodeNewGeometry", -1200, 0)
    # coordenadas do plano da superfície (paredes em xz, chão em xy)
    sep = no(nt, "ShaderNodeSeparateXYZ", -1000, 0); L.new(geo.outputs["Position"], sep.inputs[0])
    comb = no(nt, "ShaderNodeCombineXYZ", -800, 0)
    a, b = ("X", "Z") if plano == "xz" else ("X", "Y")
    L.new(sep.outputs[a], comb.inputs[0]); L.new(sep.outputs[b], comb.inputs[1]); L.new(sep.outputs["Y" if plano == "xz" else "Z"], comb.inputs[2])
    manchas = no(nt, "ShaderNodeTexNoise", -600, 300); manchas.inputs["Scale"].default_value = 0.35 * escala
    manchas.inputs["Detail"].default_value = 6; manchas.inputs["Roughness"].default_value = 0.62
    L.new(geo.outputs["Position"], manchas.inputs["Vector"])
    fino = no(nt, "ShaderNodeTexNoise", -600, 0); fino.inputs["Scale"].default_value = 6.0 * escala
    fino.inputs["Detail"].default_value = 8
    L.new(geo.outputs["Position"], fino.inputs["Vector"])
    cor = rampa(nt, [(0.25, escuro), (0.75, claro)], -350, 300)
    L.new(manchas.outputs["Fac"], cor.inputs[0])
    base = cor.outputs[0]
    fac_junta = None
    if juntas:
        tij = no(nt, "ShaderNodeTexBrick", -600, -300)
        tij.inputs["Scale"].default_value = 1.0
        tij.inputs["Mortar Size"].default_value = 0.035
        tij.inputs["Mortar Smooth"].default_value = 0.4
        tij.inputs["Brick Width"].default_value = juntas[0]
        tij.inputs["Row Height"].default_value = juntas[1]
        tij.inputs["Color1"].default_value = (1, 1, 1, 1); tij.inputs["Color2"].default_value = (0.55, 0.55, 0.55, 1)
        tij.offset = 0.5; tij.squash = 1.0
        # quebra a regularidade das juntas com ruído
        dist = no(nt, "ShaderNodeVectorMath", -750, -300, operation="ADD")
        dn = no(nt, "ShaderNodeTexNoise", -950, -450); dn.inputs["Scale"].default_value = 1.5
        L.new(geo.outputs["Position"], dn.inputs["Vector"])
        esc = no(nt, "ShaderNodeVectorMath", -850, -450, operation="SCALE"); esc.inputs["Scale"].default_value = 0.06
        L.new(dn.outputs["Color"], esc.inputs[0])
        L.new(comb.outputs[0], dist.inputs[0]); L.new(esc.outputs[0], dist.inputs[1])
        L.new(dist.outputs[0], tij.inputs["Vector"])
        mix = no(nt, "ShaderNodeMix", -150, 250, data_type="RGBA", blend_type="MULTIPLY")
        mix.inputs["Factor"].default_value = 1.0
        L.new(base, mix.inputs[6]); L.new(tij.outputs["Color"], mix.inputs[7])
        base = mix.outputs[2]
        fac_junta = tij.outputs["Fac"]
    # granulado fino
    g = no(nt, "ShaderNodeMix", 50, 250, data_type="RGBA", blend_type="OVERLAY")
    g.inputs["Factor"].default_value = 0.35
    L.new(base, g.inputs[6]); L.new(fino.outputs["Color"], g.inputs[7])
    base = g.outputs[2]
    # sujeira e musgo nos cantos (oclusão)
    ao = no(nt, "ShaderNodeAmbientOcclusion", -350, -650); ao.samples = 8; ao.inputs["Distance"].default_value = 0.9
    mr = rampa(nt, [(0.35, "#ffffff"), (0.85, "#000000")], -150, -650)
    L.new(ao.outputs["AO"], mr.inputs[0])
    mn = no(nt, "ShaderNodeTexNoise", -350, -900); mn.inputs["Scale"].default_value = 2.2
    L.new(geo.outputs["Position"], mn.inputs["Vector"])
    mfac = no(nt, "ShaderNodeMath", 50, -700, operation="MULTIPLY")
    L.new(mr.outputs[0], mfac.inputs[0]); L.new(mn.outputs["Fac"], mfac.inputs[1])
    mfac2 = no(nt, "ShaderNodeMath", 220, -700, operation="MULTIPLY"); mfac2.inputs[1].default_value = musgo * 2.2
    L.new(mfac.outputs[0], mfac2.inputs[0])
    sujo = no(nt, "ShaderNodeMix", 420, 150, data_type="RGBA")
    L.new(mfac2.outputs[0], sujo.inputs["Factor"])
    L.new(base, sujo.inputs[6]); sujo.inputs[7].default_value = hexa("#24321f")
    base = sujo.outputs[2]
    # quinas gastas mais claras (luz pega na borda)
    bev = no(nt, "ShaderNodeBevel", 600, -350); bev.samples = 6; bev.inputs["Radius"].default_value = 0.05
    L.new(bev.outputs[0], bsdf.inputs["Normal"])
    if brilho_borda > 0:
        pt = no(nt, "ShaderNodeNewGeometry", 400, -500)
        pr = rampa(nt, [(0.5, "#000000"), (0.62, "#ffffff")], 600, -550)
        L.new(pt.outputs["Pointiness"], pr.inputs[0])
        bb = no(nt, "ShaderNodeMix", 800, 150, data_type="RGBA", blend_type="SCREEN")
        f = no(nt, "ShaderNodeMath", 800, -550, operation="MULTIPLY"); f.inputs[1].default_value = brilho_borda
        L.new(pr.outputs[0], f.inputs[0]); L.new(f.outputs[0], bb.inputs["Factor"])
        L.new(base, bb.inputs[6]); bb.inputs[7].default_value = hexa(claro)
        base = bb.outputs[2]
    L.new(base, bsdf.inputs["Base Color"])
    # relevo das juntas
    if fac_junta is not None:
        bump = no(nt, "ShaderNodeBump", 900, -300); bump.inputs["Strength"].default_value = 0.6
        L.new(fac_junta, bump.inputs["Height"]); L.new(bev.outputs[0], bump.inputs["Normal"])
        L.new(bump.outputs[0], bsdf.inputs["Normal"])
    return m

def mat_simples(nome, c, rug=0.7, metal=0.0, emis=None, forca=0.0):
    m = bpy.data.materials.new(nome); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexa(c); b.inputs["Roughness"].default_value = rug
    b.inputs["Metallic"].default_value = metal
    if emis:
        b.inputs["Emission Color"].default_value = hexa(emis); b.inputs["Emission Strength"].default_value = forca
    return m

def mat_vitral(nome, paleta, escala=3.0, forca=3.0):
    """Vitral: células de vidro coloridas com chumbo preto; deixa a luz da lua passar tingida."""
    m = bpy.data.materials.new(nome); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear(); L = nt.links
    out = no(nt, "ShaderNodeOutputMaterial", 900, 0)
    geo = no(nt, "ShaderNodeNewGeometry", -900, 0)
    vor = no(nt, "ShaderNodeTexVoronoi", -650, 100); vor.inputs["Scale"].default_value = escala
    vor.inputs["Randomness"].default_value = 0.85
    L.new(geo.outputs["Position"], vor.inputs["Vector"])
    bor = no(nt, "ShaderNodeTexVoronoi", -650, -200, feature="DISTANCE_TO_EDGE"); bor.inputs["Scale"].default_value = escala
    bor.inputs["Randomness"].default_value = 0.85
    L.new(geo.outputs["Position"], bor.inputs["Vector"])
    sepc = no(nt, "ShaderNodeSeparateColor", -450, 100); L.new(vor.outputs["Color"], sepc.inputs[0])
    pal = rampa(nt, [(i / len(paleta), c) for i, c in enumerate(paleta)], -250, 150, "CONSTANT")
    L.new(sepc.outputs[0], pal.inputs[0])
    chumbo = rampa(nt, [(0.0, "#000000"), (0.08, "#000000"), (0.12, "#ffffff")], -250, -200)
    L.new(bor.outputs["Distance"], chumbo.inputs[0])
    barras = no(nt, "ShaderNodeTexWave", -650, -500, wave_type="BANDS", bands_direction="Z")
    barras.inputs["Scale"].default_value = 0.9; barras.inputs["Distortion"].default_value = 0.0
    L.new(geo.outputs["Position"], barras.inputs["Vector"])
    br = rampa(nt, [(0.0, "#000000"), (0.05, "#000000"), (0.1, "#ffffff")], -450, -500)
    L.new(barras.outputs["Fac"], br.inputs[0])
    ch2 = no(nt, "ShaderNodeMix", -100, -300, data_type="RGBA", blend_type="MULTIPLY"); ch2.inputs["Factor"].default_value = 1.0
    L.new(chumbo.outputs[0], ch2.inputs[6]); L.new(br.outputs[0], ch2.inputs[7])
    vidro = no(nt, "ShaderNodeMix", 0, 100, data_type="RGBA", blend_type="MULTIPLY"); vidro.inputs["Factor"].default_value = 1.0
    L.new(pal.outputs[0], vidro.inputs[6]); L.new(ch2.outputs[2], vidro.inputs[7])
    # brilho irregular dentro de cada vidro
    var = no(nt, "ShaderNodeTexNoise", -250, -450); var.inputs["Scale"].default_value = 9.0
    L.new(geo.outputs["Position"], var.inputs["Vector"])
    vr = rampa(nt, [(0.3, "#383838"), (0.8, "#ffffff")], 0, -450); L.new(var.outputs["Fac"], vr.inputs[0])
    v2 = no(nt, "ShaderNodeMix", 200, 100, data_type="RGBA", blend_type="MULTIPLY"); v2.inputs["Factor"].default_value = 1.0
    L.new(vidro.outputs[2], v2.inputs[6]); L.new(vr.outputs[0], v2.inputs[7])
    em = no(nt, "ShaderNodeEmission", 450, 150); em.inputs["Strength"].default_value = forca
    L.new(v2.outputs[2], em.inputs["Color"])
    tr = no(nt, "ShaderNodeBsdfTransparent", 450, -50); L.new(v2.outputs[2], tr.inputs["Color"])
    ad = no(nt, "ShaderNodeAddShader", 680, 50)
    L.new(em.outputs[0], ad.inputs[0]); L.new(tr.outputs[0], ad.inputs[1])
    L.new(ad.outputs[0], out.inputs[0])
    return m

def materiais():
    M = {}
    M["parede"] = mat_pedra("parede", "#6d7186", "#3a3d52", 1.0, juntas=(0.9, 0.42), musgo=0.35)
    M["pilar"] = mat_pedra("pilar", "#74778c", "#3d4054", 1.2, juntas=(4.0, 0.62), musgo=0.3)
    M["entalhe"] = mat_pedra("entalhe", "#8e8ea0", "#4b4c5e", 1.5, musgo=0.2, brilho_borda=0.45)
    M["chao"] = mat_pedra("chao", "#5e6076", "#2c2d3c", 0.8, juntas=(1.25, 0.9), musgo=0.5, rug=0.55, plano="xy")
    M["entulho"] = mat_pedra("entulho", "#6a6c7e", "#33354a", 2.0, musgo=0.5)
    M["longe"] = mat_pedra("longe", "#3b4166", "#1c2038", 0.5, juntas=None, musgo=0.0, brilho_borda=0.0)
    M["madeira"] = mat_simples("madeira", "#3b2a22", 0.8)
    M["ferro"] = mat_simples("ferro", "#1c1c24", 0.45, 0.8)
    M["ouro"] = mat_simples("ouro", "#b48a3c", 0.35, 1.0)
    M["brasa"] = mat_simples("brasa", "#2a1208", 0.6, emis="#ff6a1a", forca=12.0)
    M["vela"] = mat_simples("vela", "#e8dcc0", 0.6, emis="#ffb050", forca=0.6)
    M["pano"] = mat_simples("pano", "#5a1424", 0.95)
    M["vitralA"] = mat_vitral("vitralA", ["#142a7a", "#1d3d9e", "#8a1a30", "#16307e", "#2a4fb8", "#c08a2a", "#14286e", "#4a2a90", "#1b3590", "#7a1428"], 4.2, 0.9)
    M["vitralB"] = mat_vitral("vitralB", ["#7a1428", "#9a1e30", "#c08a2a", "#14286e", "#5a1838", "#8a1a30", "#2a3f9e", "#6a1426"], 4.6, 1.0)
    M["janela_luz"] = mat_simples("janela_luz", "#000000", emis="#9fb4ff", forca=0.0)
    return M

# ------------------------------------------------------------------ formas
def caixa(nome, c, t, colecao, mat, bev=0.05, seg=2, cortes=0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    if cortes:
        # malha dividida: o boolean não deixa uma face única cobrindo um furo
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cortes, use_grid_fill=True)
    for v in bm.verts:
        v.co = Vector((v.co.x * t[0] + c[0], v.co.y * t[1] + c[1], v.co.z * t[2] + c[2]))
    ob = obj_de_bm(nome, bm, colecao, mat)
    if bev: bevel(ob, bev, seg)
    return ob

def cilindro(nome, c, r, h, colecao, mat, seg=20, bev=0.03, r2=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    for v in bm.verts: v.co += Vector((c[0], c[1], c[2] + h / 2))
    ob = obj_de_bm(nome, bm, colecao, mat)
    suave(ob)
    if bev: bevel(ob, bev, 2, 60)
    return ob

def toro_x(nome, c, comp, r, colecao, mat):
    """Moldura redonda deitada ao longo de x (cordão de pedra)."""
    ob = cilindro(nome, (0, 0, -comp / 2), r, comp, colecao, mat, 12, 0)
    ob.rotation_euler = (0, math.pi / 2, 0); ob.location = c
    return ob

def ogiva_pts(larg, alt_reta, n=14, folga=0.0):
    """Contorno de um arco ogival (gótico) com a base em y=0, aberto embaixo: pontos de baixo-esq. até baixo-dir."""
    w = larg / 2.0
    R = larg * 0.85
    pts = [(-w, 0.0), (-w, alt_reta)]
    # arco esquerdo: centro em (-w + R, alt_reta)
    cx = -w + R
    ang_topo = math.acos(cx / R) if abs(cx / R) <= 1 else 0.0  # ângulo onde x = 0
    for i in range(1, n + 1):
        a = math.pi - (math.pi - ang_topo) * i / n
        pts.append((cx + R * math.cos(a), alt_reta + R * math.sin(a)))
    topo = pts[-1]
    dir_ = [(-x, y) for (x, y) in reversed(pts[2:-1])]
    pts = pts + dir_ + [(w, alt_reta), (w, 0.0)]
    return pts, topo[1]

def prisma(nome, pts2d, y0, prof, colecao, mat, plano="xz", base=(0, 0)):
    """Extruda um polígono 2D (x, z) em profundidade y."""
    bm = bmesh.new()
    vs = [bm.verts.new((base[0] + x, y0, base[1] + z)) for (x, z) in pts2d]
    f = bm.faces.new(vs)
    bmesh.ops.recalc_face_normals(bm, faces=[f])
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    nv = [e for e in r["geom"] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=nv, vec=(0, prof, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return obj_de_bm(nome, bm, colecao, mat)

def anel_ogiva(nome, larg, alt_reta, esp, y0, prof, colecao, mat, cx, base_z):
    """Arco moldado: faixa entre duas ogivas (externa e interna)."""
    ext, _ = ogiva_pts(larg + esp * 2, alt_reta, 18)
    inn, _ = ogiva_pts(larg, alt_reta, 18)
    ext = ext[1:-1]; inn = inn[1:-1]
    pts = ext + list(reversed(inn))
    ob = prisma(nome, pts, y0, prof, colecao, mat, base=(cx, base_z))
    return ob

def rocha(nome, c, tam, colecao, mat, sub=2, forca=0.35):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
    ob = obj_de_bm(nome, bm, colecao, mat)
    ob.location = c
    ob.rotation_euler = (random.uniform(-0.4, 0.4), random.uniform(-0.4, 0.4), random.uniform(0, 6.28))
    tx = bpy.data.textures.new(nome + "_t", "VORONOI"); tx.noise_scale = 0.6 + random.random() * 0.4
    d = ob.modifiers.new("d", "DISPLACE"); d.texture = tx; d.strength = forca * max(tam); d.mid_level = 0.6
    dec = ob.modifiers.new("dec", "DECIMATE"); dec.decimate_type = "DISSOLVE"; dec.angle_limit = math.radians(12)
    return ob

def cortador_irregular(nome, c, tam, forca=0.45):
    """Volume com borda quebrada para recortar ruínas (boolean)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=4, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * tam[0], v.co.y * tam[1], v.co.z * tam[2]))
    ob = obj_de_bm(nome, bm, "aux")
    ob.location = c
    tx = bpy.data.textures.new(nome + "_t", "VORONOI"); tx.noise_scale = 0.9
    d = ob.modifiers.new("d", "DISPLACE"); d.texture = tx; d.strength = forca * max(tam) * 0.5
    ob.hide_render = True
    return ob

def recortar(ob, cortador):
    m = ob.modifiers.new("bool", "BOOLEAN"); m.operation = "DIFFERENCE"; m.object = cortador; m.solver = "MANIFOLD"
    # o bevel tem de vir antes do boolean, senão chanfra o corte inteiro
    return m

def mover_mod_fim(ob, nome):
    while ob.modifiers.find(nome) < len(ob.modifiers) - 1:
        with bpy.context.temp_override(object=ob):
            bpy.ops.object.modifier_move_down(modifier=nome)

def faixa_obj(o):
    xs = [(o.matrix_basis @ v.co).x for v in o.data.vertices]
    return min(xs), max(xs)

def paineis(nome, y, prof, z0, z1, colecao, mat, cortadores, bev=0.03):
    """Parede em painéis (um por baia), cada um só com os recortes que caem nele.
    Muitos recortes numa malha só faziam o boolean apagar a parede inteira."""
    fx = [(c, faixa_obj(c)) for c in cortadores]
    obs = []
    xs = [X_MIN] + [p for p in PILARES if X_MIN < p < X_MAX] + [X_MAX]
    for i in range(len(xs) - 1):
        a, b = xs[i], xs[i + 1]
        pn = caixa(f"{nome}{i}", ((a + b) / 2, y + prof / 2, (z0 + z1) / 2), (b - a + 0.02, prof, z1 - z0), colecao, mat, 0, cortes=7)
        for c, (c0, c1) in fx:
            if c1 > a and c0 < b:
                recortar(pn, c)
        obs.append(pn)
    return obs

# ------------------------------------------------------------------ peças da catedral
def pilar_composto(i, x, y, alt, M, quebrado=False):
    """Pilar gótico: núcleo com quatro colunetas, base moldada e capitel."""
    c = "perto"
    pe = []
    pe.append(caixa(f"plinto{i}", (x, y, 0.22), (1.9, 1.9, 0.44), c, M["entalhe"], 0.06))
    pe.append(caixa(f"plinto2_{i}", (x, y, 0.56), (1.65, 1.65, 0.24), c, M["entalhe"], 0.05))
    pe.append(cilindro(f"toro{i}", (x, y, 0.68), 0.95, 0.16, c, M["entalhe"], 28, 0.06))
    topo = alt
    pe.append(caixa(f"nucleo{i}", (x, y, 0.76 + (topo - 0.76) / 2), (1.05, 1.05, topo - 0.76), c, M["pilar"], 0.08))
    for dx, dy in ((0.55, 0), (-0.55, 0), (0, -0.55), (0, 0.55)):
        pe.append(cilindro(f"colun{i}_{dx}_{dy}", (x + dx, y + dy, 0.76), 0.24, topo - 0.76, c, M["pilar"], 16, 0.02))
        pe.append(cilindro(f"anel{i}_{dx}_{dy}", (x + dx, y + dy, 3.4), 0.29, 0.12, c, M["entalhe"], 16, 0.02))
    for dx, dy in ((0.4, -0.4), (-0.4, -0.4)):
        pe.append(cilindro(f"colfina{i}_{dx}", (x + dx, y + dy, 0.76), 0.11, topo - 0.76, c, M["pilar"], 10, 0.0))
    if quebrado:
        cort = cortador_irregular(f"quebra{i}", (x, y, topo + 0.2), (1.6, 1.6, 0.9), 0.9)
        for p in pe:
            if p.location.z == 0 and p.dimensions.z + 0 > 0:
                pass
        for p in pe[3:]:
            recortar(p, cort)
        return pe
    # capitel com folhagem estilizada (anel de "folhas" de pedra) e ábaco
    pe.append(cilindro(f"capA{i}", (x, y, topo), 0.85, 0.35, c, M["entalhe"], 24, 0.04, r2=1.15))
    for k in range(8):
        a = k / 8 * math.tau
        fol = rocha(f"folha{i}_{k}", (x + math.cos(a) * 0.82, y + math.sin(a) * 0.82, topo + 0.12), (0.22, 0.14, 0.26), c, M["entalhe"], 1, 0.15)
    pe.append(caixa(f"abaco{i}", (x, y, topo + 0.48), (2.5, 2.5, 0.26), c, M["entalhe"], 0.05))
    return pe

def arcada(M):
    """Parede da arcada (perto): pilares, arcos ogivais moldados e parede acima com friso."""
    y = Y_ARCADA
    larg_vao = BAIA - 2.4
    # parede acima dos arcos, recortada pelos vãos
    cortes = []
    for k in range(len(PILARES) - 1):
        cx = (PILARES[k] + PILARES[k + 1]) / 2
        pts, topo = ogiva_pts(larg_vao, ALT_IMPOSTA + 0.6 - 0.0, 18)
        vao = prisma(f"vao{k}", pts, y - 2, 4.0, "aux", None, base=(cx, -0.5))
        vao.hide_render = True
        cortes.append(vao)
        if k in ARCO_QUEBRADO:
            cort = cortador_irregular(f"ruina{k}", (cx + random.uniform(-1, 1), y, 11.2), (4.4, 2.5, 3.2), 1.0)
            cortes.append(cort)
        else:
            # aduelas: arco moldado em duas ordens na frente da parede
            a1 = anel_ogiva(f"arco{k}a", larg_vao, ALT_IMPOSTA + 0.6, 0.38, y - 0.25, 0.4, "perto", M["entalhe"], cx, -0.5)
            a2 = anel_ogiva(f"arco{k}b", larg_vao - 0.5, ALT_IMPOSTA + 0.6, 0.28, y - 0.45, 1.6, "perto", M["pilar"], cx, -0.5)
            bevel(a1, 0.05, 2, 30); bevel(a2, 0.04, 2, 30)
            # pedra-chave
            caixa(f"chave{k}", (cx, y - 0.4, topo - 0.5 + 0.55), (0.5, 0.3, 0.75), "perto", M["entalhe"], 0.05)
    # friso (cornija) ao longo da parede
    caixa("cornija", ((X_MIN + X_MAX) / 2, y - 0.15, 11.6), (X_MAX - X_MIN, 0.5, 0.3), "perto", M["entalhe"], 0.06)
    toro_x("cordao", ((X_MIN + X_MAX) / 2, y - 0.05, 11.35), X_MAX - X_MIN, 0.12, "perto", M["entalhe"])
    # trifório: arcadinhas cegas acima da cornija
    for k in range(len(PILARES) - 1):
        if k in ARCO_QUEBRADO: continue
        cx = (PILARES[k] + PILARES[k + 1]) / 2
        for j in range(4):
            bx = cx - 2.4 + j * 1.6
            pts, _ = ogiva_pts(0.9, 1.0, 8)
            n = prisma(f"trif{k}_{j}", pts, y - 0.3, 0.5, "aux", None, base=(bx, 11.9))
            n.hide_render = True
            cortes.append(n)
            cilindro(f"trifc{k}_{j}", (bx + 0.8, y - 0.05, 11.75), 0.08, 1.25, "perto", M["entalhe"], 8, 0)
    for k, x in enumerate(PILARES):
        quebrado = k in PILAR_QUEBRADO
        alt = PILAR_QUEBRADO.get(k, ALT_IMPOSTA)
        pilar_composto(k, x, y - 0.55, alt, M, quebrado)
        if quebrado:
            # o pedaço da parede acima também caiu
            cort = cortador_irregular(f"ruinaP{k}", (x, y, 9.5), (3.4, 2.5, 4.5), 1.0)
            cortes.append(cort)
            for j in range(9):
                rocha(f"tambor{k}_{j}", (x + random.uniform(-2.5, 3.0), y - 1.5 + random.uniform(-1.4, 0.8), 0.25),
                      (random.uniform(0.3, 0.6), random.uniform(0.3, 0.6), random.uniform(0.2, 0.45)), "perto", M["entulho"])
            # tambor de coluna caído, deitado
            t = cilindro(f"caido{k}", (0, 0, -0.9), 0.52, 1.8, "perto", M["pilar"], 18, 0.05)
            t.rotation_euler = (0, math.pi / 2, 0.5); t.location = (x + 2.2, y - 2.0, 0.5)
    return paineis("arcada", y, 1.2, 0.0, 13.0, "perto", M["parede"], cortes)

def lanceta(nome, cx, base_z, larg, alt, y, M, mat_vidro, colecao="meio"):
    pts, topo = ogiva_pts(larg, alt, 14)
    furo = prisma(nome + "_furo", pts, y - 1.5, 3.0, "aux", None, base=(cx, base_z))
    furo.hide_render = True
    vidro = prisma(nome + "_vidro", pts, y + 0.45, 0.04, colecao, mat_vidro, base=(cx, base_z))
    # moldura (chanfro) e mainel
    moldura = anel_ogiva(nome + "_mold", larg, alt, 0.16, y - 0.12, 0.25, colecao, M["entalhe"], cx, base_z)
    bevel(moldura, 0.03, 2, 30)
    return furo, topo

def oculo(nome, cx, cz, r, y, M, mat_vidro, petalas=6, colecao="meio"):
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=40, radius=r)
    for v in bm.verts: v.co = Vector((cx + v.co.x, y - 1.5, cz + v.co.y))
    f = bm.faces[:]
    r_ = bmesh.ops.extrude_face_region(bm, geom=f)
    bmesh.ops.translate(bm, verts=[e for e in r_["geom"] if isinstance(e, bmesh.types.BMVert)], vec=(0, 3.0, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    furo = obj_de_bm(nome + "_furo", bm, "aux"); furo.hide_render = True
    vid = cilindro(nome + "_vidro", (0, 0, 0), r, 0.04, colecao, mat_vidro, 40, 0)
    vid.rotation_euler = (math.pi / 2, 0, 0); vid.location = (cx, y + 0.47, cz)
    aro = bpy.data.objects.new(nome + "_aro", bpy.data.meshes.new(nome + "_aro"))
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, segments=48, radius=r + 0.1)
    # traceria: anel + raios + pétalas (anéis pequenos)
    bm.free()
    for k in range(petalas):
        a = k / petalas * math.tau
        tc = cilindro(f"{nome}_raio{k}", (0, 0, 0), 0.06, r * 0.95, colecao, M["entalhe"], 8, 0)
        tc.rotation_euler = (0, a, 0); tc.location = (cx, y + 0.3, cz)
        pc = toro(f"{nome}_pet{k}", (cx + math.cos(a + math.pi / petalas) * r * 0.55, y + 0.3, cz + math.sin(a + math.pi / petalas) * r * 0.55), r * 0.32, 0.05, colecao, M["entalhe"])
    toro(f"{nome}_anel", (cx, y + 0.2, cz), r + 0.08, 0.12, colecao, M["entalhe"])
    toro(f"{nome}_anelint", (cx, y + 0.3, cz), r * 0.22, 0.06, colecao, M["entalhe"])
    return furo

def toro(nome, c, R, r, colecao, mat):
    bm = bmesh.new()
    seg, ss = 40, 8
    vs = []
    for i in range(seg):
        a = i / seg * math.tau
        anel = []
        for j in range(ss):
            b = j / ss * math.tau
            p = Vector(((R + r * math.cos(b)) * math.cos(a), r * math.sin(b), (R + r * math.cos(b)) * math.sin(a)))
            anel.append(bm.verts.new(p))
        vs.append(anel)
    for i in range(seg):
        for j in range(ss):
            bm.faces.new([vs[i][j], vs[(i + 1) % seg][j], vs[(i + 1) % seg][(j + 1) % ss], vs[i][(j + 1) % ss]])
    ob = obj_de_bm(nome, bm, colecao, mat); suave(ob); ob.location = c
    return ob

def muro_vitrais(M):
    """Parede externa (meio): vitrais em par com óculo, contrafortes, e a grande rosácea atrás da arena."""
    y = Y_MURO
    furos = []
    for k in range(len(PILARES) - 1):
        cx = (PILARES[k] + PILARES[k + 1]) / 2
        if cx > 86 and cx < 106:
            continue
        if k in MURO_CAIDO:
            cort = cortador_irregular(f"muroCaido{k}", (cx, y, 9.0), (4.6, 2.5, 9.5), 1.1)
            furos.append(cort)
            for j in range(14):
                rocha(f"entMuro{k}_{j}", (cx + random.uniform(-4, 4), y - random.uniform(0.5, 3.5), 0.2),
                      (random.uniform(0.3, 0.9), random.uniform(0.3, 0.8), random.uniform(0.25, 0.6)), "meio", M["entulho"])
            continue
        vid = M["vitralA"] if k % 3 != 1 else M["vitralB"]
        for dx in (-1.05, 1.05):
            f, _ = lanceta(f"lan{k}_{dx}", cx + dx, 2.6, 1.5, 5.4, y, M, vid)
            furos.append(f)
        furos.append(oculo(f"ocu{k}", cx, 10.6, 0.95, y, M, vid, 6))
        # mainel central e peitoril
        caixa(f"peit{k}", (cx, y - 0.25, 2.5), (4.2, 0.6, 0.22), "meio", M["entalhe"], 0.04)
    # rosácea da Ordem (oito pétalas) atrás da arena do chefe
    furos.append(oculo("rosa", ROSA_X, 8.4, 3.6, y, M, M["vitralB"], 8))
    for k in range(16):
        a = k / 16 * math.tau
        rocha(f"rosaPed{k}", (ROSA_X + math.cos(a) * 3.95, y - 0.1, 8.4 + math.sin(a) * 3.95), (0.42, 0.25, 0.32), "meio", M["entalhe"], 1, 0.08)
    for (lx) in (ROSA_X - 6.2, ROSA_X + 6.2):
        f, _ = lanceta(f"lanR{lx}", lx, 2.0, 1.3, 7.0, y, M, M["vitralA"])
        furos.append(f)
    muro = paineis("muro", y, 1.0, 0.0, 18.0, "meio", M["parede"], furos, 0.02)
    # contrafortes (pilastras com colunetas) alinhados aos pilares
    for k, x in enumerate(PILARES):
        caixa(f"pilastra{k}", (x, y - 0.35, 9.0), (1.3, 0.7, 18.0), "meio", M["pilar"], 0.06)
        cilindro(f"pilcol{k}", (x, y - 0.75, 0.0), 0.22, 14.0, "meio", M["pilar"], 12, 0)
        caixa(f"pilbase{k}", (x, y - 0.5, 0.45), (1.7, 1.2, 0.9), "meio", M["entalhe"], 0.05)
    # banco de pedra corrido e túmulos encostados
    caixa("banco", ((X_MIN + X_MAX) / 2, y - 0.6, 0.35), (X_MAX - X_MIN, 0.7, 0.7), "meio", M["entalhe"], 0.05)
    return muro

def bancos(M):
    """Bancos de madeira da nave, tombados e quebrados (entre a arcada e o muro)."""
    for k in range(len(PILARES) - 1):
        cx = (PILARES[k] + PILARES[k + 1]) / 2
        if 86 < cx < 106 or k in MURO_CAIDO:
            continue
        for j in range(random.randint(1, 3)):
            bx = cx + random.uniform(-2.5, 2.5); by = random.uniform(8.0, 11.5)
            ang = random.uniform(-0.25, 0.25)
            tomb = random.random() < 0.4
            assento = caixa(f"banco{k}_{j}", (0, 0, 0.55), (2.6, 0.5, 0.1), "meio", M["madeira"], 0.02)
            enc = caixa(f"encosto{k}_{j}", (0, 0.22, 0.95), (2.6, 0.08, 0.7), "meio", M["madeira"], 0.02)
            pes = [caixa(f"pe{k}_{j}_{s}", (s * 1.15, 0.05, 0.3), (0.1, 0.45, 0.6), "meio", M["madeira"], 0.01) for s in (-1, 1)]
            vazio = bpy.data.objects.new(f"bancoG{k}_{j}", None); col("meio").objects.link(vazio)
            for o in [assento, enc] + pes: o.parent = vazio
            vazio.location = (bx, by, 0.0)
            vazio.rotation_euler = ((1.35 if tomb else 0.0), 0, ang)
            if tomb: vazio.location.z = 0.3

def chao(M):
    """Chão de lajes e a borda da frente (o jogador anda em y=0)."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
    for v in bm.verts:
        v.co = Vector(((X_MIN + X_MAX) / 2 + v.co.x * (X_MAX - X_MIN), 9.0 + v.co.y * 22.0, 0.0))
    c = obj_de_bm("chao", bm, "chao", M["chao"])
    # borda da frente: bloco grosso, cordão de pedra e blocos irregulares embaixo
    yb = -1.2
    caixa("borda_fundo", ((X_MIN + X_MAX) / 2, yb + 0.9, -1.2), (X_MAX - X_MIN, 0.6, 2.4), "borda", M["parede"], 0)
    caixa("borda_topo", ((X_MIN + X_MAX) / 2, yb + 0.25, -0.18), (X_MAX - X_MIN, 0.5, 0.36), "borda", M["entalhe"], 0.06)
    toro_x("borda_cordao", ((X_MIN + X_MAX) / 2, yb - 0.02, -0.42), X_MAX - X_MIN, 0.13, "borda", M["entalhe"])
    x = X_MIN
    while x < X_MAX:
        w = random.uniform(1.0, 2.2)
        b = caixa(f"bloco{x:.1f}", (x + w / 2, yb + 0.5 + random.uniform(-0.05, 0.08), -1.3), (w - 0.06, 1.0, 1.6), "borda", M["entulho"], 0.09)
        x += w
    # musgo/raízes pendendo da borda
    for i in range(70):
        rx = random.uniform(X_MIN, X_MAX)
        rocha(f"musgo{i}", (rx, yb - 0.08, -0.55 - random.uniform(0, 0.3)), (random.uniform(0.15, 0.4), 0.08, random.uniform(0.15, 0.35)), "borda", M["entulho"], 1, 0.2)
    # pedrinhas soltas, lajes rachadas
    for i in range(160):
        rx = random.uniform(X_MIN, X_MAX); ry = random.uniform(-0.8, 13.0)
        s = random.uniform(0.06, 0.22)
        rocha(f"pedrinha{i}", (rx, ry, 0.02), (s, s * random.uniform(0.6, 1.2), s * 0.6), "chao", M["entulho"], 1, 0.25)

def braseiros(M):
    for k in BRASEIROS:
        x = PILARES[k] + 1.7
        y = Y_ARCADA - 2.0
        cilindro(f"bpe{k}", (x, y, 0.0), 0.05, 1.5, "perto", M["ferro"], 8, 0)
        for a in (0, 2.1, 4.2):
            p = cilindro(f"bpata{k}_{a}", (0, 0, 0), 0.035, 0.6, "perto", M["ferro"], 6, 0)
            p.rotation_euler = (0.5, 0, a); p.location = (x + math.sin(a) * 0.22, y - math.cos(a) * 0.22, 0.0)
        cilindro(f"bcuba{k}", (x, y, 1.45), 0.18, 0.28, "perto", M["ferro"], 16, 0.02, r2=0.42)
        cilindro(f"bbrasa{k}", (x, y, 1.62), 0.36, 0.12, "perto", M["brasa"], 14, 0)
        l = bpy.data.lights.new(f"fogo{k}", "POINT"); l.energy = 260; l.color = hexa("#ff8a3a")[:3]; l.shadow_soft_size = 0.25
        o = bpy.data.objects.new(f"fogo{k}", l); col("aux").objects.link(o); o.location = (x, y, 2.05)
        FOGOS.append((x, y, 2.0))
    # velas em grupos na base dos pilares
    for k in range(len(PILARES)):
        if random.random() < 0.55:
            for j in range(random.randint(3, 6)):
                vx = PILARES[k] + random.uniform(-1.2, 1.2); vy = Y_ARCADA - 1.9 - random.uniform(0, 0.6)
                h = random.uniform(0.12, 0.4)
                cilindro(f"vela{k}_{j}", (vx, vy, 0.0), 0.045, h, "perto", M["vela"], 8, 0)
            l = bpy.data.lights.new(f"velas{k}", "POINT"); l.energy = 14; l.color = hexa("#ffb060")[:3]
            o = bpy.data.objects.new(f"velasL{k}", l); col("aux").objects.link(o); o.location = (PILARES[k], Y_ARCADA - 2.2, 0.5)

def estandartes(M):
    for k in (2, 7, 14):
        x = PILARES[k]
        bm = bmesh.new()
        w, h = 1.1, 3.4
        pts = [(-w / 2, 0), (w / 2, 0), (w / 2, -h + 0.5), (w / 4, -h + 0.1), (0, -h + 0.6), (-w / 4, -h), (-w / 2, -h + 0.45)]
        vs = [bm.verts.new((x + px, Y_ARCADA - 1.65, 5.6 + py)) for (px, py) in pts]
        bm.faces.new(vs)
        ob = obj_de_bm(f"estand{k}", bm, "perto", M["pano"])
        s = ob.modifiers.new("s", "SOLIDIFY"); s.thickness = 0.03
        caixa(f"estbar{k}", (x, Y_ARCADA - 1.65, 5.62), (1.4, 0.06, 0.06), "perto", M["ouro"], 0.01)

def plataformas(M, plats):
    """Plataformas flutuantes: lajes quebradas presas por correntes (no plano do jogo)."""
    for i, p in enumerate(plats):
        x0 = p["x"] / 26.0; w = p["w"] / 26.0; top = (230 - p["y"]) / 26.0
        caixa(f"plat{i}", (x0 + w / 2, 0.0, top - 0.22), (w + 0.1, 1.4, 0.44), "plat", M["entalhe"], 0.07)
        sob = caixa(f"platsob{i}", (x0 + w / 2, 0.0, top - 0.62), (w * 0.82, 1.1, 0.4), "plat", M["parede"], 0.05)
        cort = cortador_irregular(f"platc{i}", (x0 + w / 2 + random.uniform(-0.3, 0.3), 0, top - 1.1), (w * 0.5, 1.2, 0.5), 0.9)
        recortar(sob, cort)
        toro_x(f"platcord{i}", (x0 + w / 2, -0.72, top - 0.3), w + 0.05, 0.08, "plat", M["entalhe"])
        for j in range(int(w * 2.5)):
            rocha(f"platmusgo{i}_{j}", (x0 + random.uniform(0.1, w - 0.1), -0.7, top - 0.45 - random.uniform(0, 0.25)),
                  (random.uniform(0.08, 0.2), 0.05, random.uniform(0.1, 0.3)), "plat", M["entulho"], 1, 0.2)
        for sx in (x0 + 0.25, x0 + w - 0.25):
            elo_z = top; n = 0
            while elo_z < top + 9:
                t = toro(f"elo{i}_{sx}_{n}", (sx, 0.0, elo_z + 0.1), 0.09, 0.025, "plat", M["ferro"])
                t.rotation_euler = (0, 0, (math.pi / 2) * (n % 2))
                elo_z += 0.15; n += 1

def longe(M):
    """Silhuetas distantes: torres, agulhas e muralhas da cidade caída de Arvália."""
    x = X_MIN - 30
    while x < X_MAX + 40:
        h = random.uniform(5, 14)
        w = random.uniform(2.0, 4.5)
        caixa(f"torre{x:.0f}", (x, Y_LONGE, h / 2 - 2), (w, 3, h), "longe", M["longe"], 0.0)
        if random.random() < 0.7:
            cilindro(f"agulha{x:.0f}", (x, Y_LONGE, h - 2), w * 0.45, random.uniform(3, 8), "longe", M["longe"], 6, 0, r2=0.02)
        if random.random() < 0.5:
            l = caixa(f"janelinha{x:.0f}", (x + random.uniform(-0.5, 0.5), Y_LONGE - 1.6, h * random.uniform(0.4, 0.8) - 2), (0.25, 0.1, 0.45), "longe", M["brasa"], 0)
        x += random.uniform(3.5, 8.0)
    caixa("muralha", ((X_MIN + X_MAX) / 2, Y_LONGE - 4, 1.0), (X_MAX - X_MIN + 120, 2, 6.0), "longe", M["longe"], 0.0)
    for i in range(40):
        rocha(f"colina{i}", (random.uniform(X_MIN - 40, X_MAX + 40), Y_LONGE + 4, -3), (random.uniform(6, 12), 3, random.uniform(3, 6)), "longe", M["longe"], 2, 0.2)

def teto(M):
    """Abóbada fora de quadro (só faz sombra), com buracos onde a luz da lua entra."""
    t = caixa("teto", ((X_MIN + X_MAX) / 2, 9.0, 16.0), (X_MAX - X_MIN, 30.0, 0.6), "aux", M["parede"], 0)
    for k in TETO_ABERTO:
        cx = (PILARES[k] + PILARES[k + 1]) / 2
        c = cortador_irregular(f"furoTeto{k}", (cx, 6.5, 16.0), (3.0, 4.0, 2.0), 0.9)
        recortar(t, c)
    t.visible_camera = False

def luzes():
    sol = bpy.data.lights.new("lua", "SUN"); sol.energy = 1.7; sol.color = hexa("#a9bbff")[:3]; sol.angle = math.radians(3.0)
    o = bpy.data.objects.new("lua", sol); col("aux").objects.link(o)
    # vem de trás (y+), de cima e um pouco da esquerda: atravessa os vitrais e chega perto do plano do jogo
    o.rotation_euler = (math.radians(48), 0, math.radians(-38))
    # o sol aponta para -Z local; girar em X negativo inclina para -Y (na direção da câmera)
    pre = bpy.data.lights.new("preenchimento", "AREA"); pre.energy = 14000; pre.size = 60; pre.color = hexa("#5a4f9a")[:3]
    o2 = bpy.data.objects.new("preenchimento", pre); col("aux").objects.link(o2)
    o2.location = ((X_MIN + X_MAX) / 2, -30, 10); o2.rotation_euler = (math.radians(80), 0, 0)
    w = bpy.data.worlds.new("mundo"); bpy.context.scene.world = w; w.use_nodes = True
    bg = w.node_tree.nodes["Background"]; bg.inputs[0].default_value = hexa("#262c5c"); bg.inputs[1].default_value = 1.6

def nevoa_volume(y0, y1):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    ob = obj_de_bm("nevoa", bm, "aux")
    ob.scale = (X_MAX - X_MIN, y1 - y0, 15); ob.location = ((X_MIN + X_MAX) / 2, (y0 + y1) / 2, 7.4)
    m = bpy.data.materials.new("nevoa"); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    v = nt.nodes.new("ShaderNodeVolumePrincipled"); v.inputs["Density"].default_value = 0.012
    v.inputs["Color"].default_value = hexa("#b9b6ff")
    nt.links.new(v.outputs[0], out.inputs["Volume"])
    ob.data.materials.append(m)
    return ob

# ------------------------------------------------------------------ montagem
def montar():
    sc = limpar()
    M = materiais()
    arcada(M)
    muro_vitrais(M)
    bancos(M)
    chao(M)
    braseiros(M)
    estandartes(M)
    plats = json.load(open(os.path.join(AQUI, "plataformas.json")))
    plataformas(M, plats)
    longe(M)
    # sem teto: ruína aberta ao luar (o teto fazia sombras duras em diagonal)
    luzes()
    return sc

def config_render(sc, amostras=48, larg=960, alt=540):
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = amostras
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 4; sc.cycles.diffuse_bounces = 2; sc.cycles.glossy_bounces = 1
    sc.cycles.transparent_max_bounces = 8; sc.cycles.volume_bounces = 0
    sc.cycles.volume_step_rate = 4.0
    sc.render.resolution_x = larg; sc.render.resolution_y = alt; sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.view_settings.exposure = 0.7
    sc.render.image_settings.file_format = "PNG"

def camera_jogo(sc, cx):
    cd = bpy.data.cameras.new("cam"); cd.sensor_fit = "VERTICAL"; cd.angle_y = math.radians(28)
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam)
    dist = (270 / 2 / 26) / math.tan(math.radians(14))
    cy = (230 - 135) / 26
    cam.location = (cx, -dist, cy); cam.rotation_euler = (math.radians(90), 0, 0)
    sc.camera = cam
    return cam

# ------------------------------------------------------------------ camadas para o Godot
D_CAM = (270 / 2 / 26) / math.tan(math.radians(14))
CY_CAM = (230 - 135) / 26
CX_MIN, CX_MAX = 240 / 26, (3150 - 240) / 26

def faixa_x(y, folga=1.2):
    k = (D_CAM + y) / D_CAM
    return CX_MIN - 9.23 * k - folga, CX_MAX + 9.23 * k + folga

def faixa_z(y, folga=0.8):
    k = (D_CAM + y) / D_CAM
    return CY_CAM - 5.19 * k - folga, CY_CAM + 5.19 * k + folga

def visiveis(sc, colecoes, extra=()):
    for ob in sc.objects:
        if ob.type in ("LIGHT", "CAMERA"):
            continue
        dono = ob.users_collection[0].name if ob.users_collection else ""
        if ob.parent is not None:
            dono = ob.parent.users_collection[0].name
        ob.visible_camera = dono in colecoes or ob.name in extra

def render_regiao(sc, nome, x0, x1, z0, z1, ppu, topo=False, y_cam=-40.0, z_cam=60.0, max_px=4096):
    """Renderiza um retângulo do mundo com câmera ortográfica (frente: plano xz; topo: plano xy) em ladrilhos."""
    cd = bpy.data.cameras.new("orto_" + nome); cd.type = "ORTHO"; cd.sensor_fit = "HORIZONTAL"
    cd.clip_start = 0.1; cd.clip_end = 300
    cam = bpy.data.objects.new("orto_" + nome, cd); sc.collection.objects.link(cam); sc.camera = cam
    larg_u = max_px / ppu
    alt_u = z1 - z0
    alt_px = int(round(alt_u * ppu))
    tiles = []
    x = x0; i = 0
    while x < x1 - 1e-3:
        w = min(larg_u, x1 - x)
        wpx = int(round(w * ppu)); w = wpx / ppu
        if wpx < 4: break
        sc.render.resolution_x = wpx; sc.render.resolution_y = alt_px
        cd.sensor_fit = "HORIZONTAL" if wpx >= alt_px else "VERTICAL"
        cd.ortho_scale = w if wpx >= alt_px else alt_u
        if topo:
            cam.location = (x + w / 2, (z0 + z1) / 2, z_cam); cam.rotation_euler = (0, 0, 0)
        else:
            cam.location = (x + w / 2, y_cam, (z0 + z1) / 2); cam.rotation_euler = (math.radians(90), 0, 0)
        arq = f"{nome}_{i}.png"
        sc.render.filepath = os.path.join(SAIDA, "_bruto", arq)
        bpy.ops.render.render(write_still=True)
        tiles.append({"arq": arq, "x0": x, "x1": x + w})
        x += w; i += 1
    return {"z0": z0, "z1": z1, "ppu": ppu, "tiles": tiles}

def renderizar_camadas(sc, so=None):
    os.makedirs(os.path.join(SAIDA, "_bruto"), exist_ok=True)
    open(os.path.join(SAIDA, "_bruto", ".gdignore"), "w").close()   # o Godot não importa os PNG brutos
    config_render(sc, int(os.environ.get("AMOSTRAS", "28")))
    sc.render.film_transparent = True
    meta_arq = os.path.join(SAIDA, "_bruto", "camadas.json")
    meta = json.load(open(meta_arq)) if os.path.exists(meta_arq) else {}
    def quer(n): return so is None or n in so
    if quer("longe"):
        visiveis(sc, {"longe"})
        x0, x1 = faixa_x(Y_LONGE); z0, z1 = faixa_z(Y_LONGE)
        meta["longe"] = render_regiao(sc, "longe", x0, x1, -6.0, z1, 22); meta["longe"]["y"] = Y_LONGE
    if quer("meio"):
        vol = nevoa_volume(5.8, Y_MURO - 0.1)
        visiveis(sc, {"meio"}, {"nevoa"})
        x0, x1 = faixa_x(Y_MURO)
        meta["meio"] = render_regiao(sc, "meio", x0, x1, -0.4, faixa_z(Y_MURO)[1], 52); meta["meio"]["y"] = Y_MURO
        bpy.data.objects.remove(vol)
    if quer("perto"):
        visiveis(sc, {"perto"})
        yq = Y_ARCADA - 1.0
        x0, x1 = faixa_x(yq)
        meta["perto"] = render_regiao(sc, "perto", x0, x1, -0.4, faixa_z(yq)[1] + 0.6, 72); meta["perto"]["y"] = yq
    if quer("chao"):
        visiveis(sc, {"chao"})
        x0, x1 = faixa_x(0.0)
        meta["chao"] = render_regiao(sc, "chao", x0, x1, -1.25, Y_MURO + 0.4, 56, topo=True); meta["chao"]["y"] = 0.0
    if quer("borda"):
        visiveis(sc, {"borda"})
        x0, x1 = faixa_x(-1.2)
        meta["borda"] = render_regiao(sc, "borda", x0, x1, -2.2, 0.15, 84); meta["borda"]["y"] = -1.2
    if quer("plat"):
        visiveis(sc, {"plat"})
        plats = json.load(open(os.path.join(AQUI, "plataformas.json")))
        meta["plat"] = []
        for i, p in enumerate(plats):
            x0 = p["x"] / 26.0 - 0.4; x1 = (p["x"] + p["w"]) / 26.0 + 0.4; top = (230 - p["y"]) / 26.0
            r = render_regiao(sc, f"plat{i}", x0, x1, top - 1.4, min(top + 9.0, 12.0), 90); r["y"] = 0.0
            meta["plat"].append(r)
    meta["fogos"] = FOGOS
    json.dump(meta, open(meta_arq, "w"), indent=1)

if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    modo = args[0] if args else "previa"
    sc = montar()
    if modo == "previa":
        destino = os.environ.get("PREVIA_DIR", "/tmp")
        config_render(sc, int(os.environ.get("AMOSTRAS", "24")), 960, 540)
        nevoa_volume(5.8, Y_MURO - 0.1)
        for xs in args[1:]:
            camera_jogo(sc, float(xs))
            sc.render.filepath = os.path.join(destino, f"previa_{xs}.png")
            bpy.ops.render.render(write_still=True)
    elif modo == "camadas":
        so = args[1:] or None
        renderizar_camadas(sc, so)
    elif modo == "salvar":
        bpy.ops.wm.save_as_mainfile(filepath=args[1])
