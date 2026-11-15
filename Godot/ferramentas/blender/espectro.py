# Espectro (monge caído da catedral), modelado, pintado, com esqueleto e animações, no Blender.
#   python espectro.py previa [anim quadro ...]   -> renders de prévia (Cycles) em /tmp ou $PREVIA_DIR
#   python espectro.py exportar                    -> assa as texturas e grava Godot/assets/inimigos/espectro_novo.glb
# O boneco olha para +X (frente), com Z para cima; o lado esquerdo (.L) fica em +Y.
import bpy, bmesh, math, random, sys, os
from mathutils import Vector, Matrix, Quaternion, Euler

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.normpath(os.path.join(AQUI, "..", "..", "assets", "inimigos"))
random.seed(11)
FPS = 30

def hexa(h, a=1.0):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    c = [((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c]
    return (c[0], c[1], c[2], a)

def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return bpy.context.scene

def obj_de_bm(nome, bm, mat=None):
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat: me.materials.append(mat)
    return ob

def suave(ob):
    for p in ob.data.polygons: p.use_smooth = True

def grupo(ob, osso, peso=1.0):
    vg = ob.vertex_groups.get(osso) or ob.vertex_groups.new(name=osso)
    vg.add(list(range(len(ob.data.vertices))), peso, "REPLACE")

# ------------------------------------------------------------------ materiais (pintura procedural, depois assada)
def no(nt, tipo, x=0, y=0, **kw):
    n = nt.nodes.new(tipo); n.location = (x, y)
    for k, v in kw.items(): setattr(n, k, v)
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

def mat_pintado(nome, claro, escuro, fundo, faixa=None, escala_tecido=18.0, ao_forca=1.0):
    """Tecido/osso 'pintado': degradê de altura (escuro embaixo), dobras escurecidas por AO, trama fina,
    e uma faixa bordada opcional perto da barra. A saída Emission é o que vai para a textura assada."""
    m = bpy.data.materials.new(nome); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear(); L = nt.links
    out = no(nt, "ShaderNodeOutputMaterial", 1300, 0)
    geo = no(nt, "ShaderNodeNewGeometry", -1100, 0)
    sep = no(nt, "ShaderNodeSeparateXYZ", -900, 200); L.new(geo.outputs["Position"], sep.inputs[0])
    alt = no(nt, "ShaderNodeMapRange", -700, 300)
    alt.inputs["From Min"].default_value = -0.2; alt.inputs["From Max"].default_value = 1.5
    L.new(sep.outputs["Z"], alt.inputs["Value"])
    grad = rampa(nt, [(0.0, fundo), (0.45, escuro), (1.0, claro)], -500, 300)
    L.new(alt.outputs["Result"], grad.inputs[0])
    base = grad.outputs[0]
    # manchas grandes (tecido velho, gasto)
    mn = no(nt, "ShaderNodeTexNoise", -700, 0); mn.inputs["Scale"].default_value = 4.0; mn.inputs["Detail"].default_value = 5
    L.new(geo.outputs["Position"], mn.inputs["Vector"])
    mm = no(nt, "ShaderNodeMix", -250, 250, data_type="RGBA", blend_type="OVERLAY"); mm.inputs["Factor"].default_value = 0.35
    L.new(base, mm.inputs[6]); L.new(mn.outputs["Color"], mm.inputs[7]); base = mm.outputs[2]
    # trama
    tr = no(nt, "ShaderNodeTexWave", -700, -250, wave_type="BANDS", bands_direction="Z")
    tr.inputs["Scale"].default_value = escala_tecido; tr.inputs["Distortion"].default_value = 2.0
    L.new(geo.outputs["Position"], tr.inputs["Vector"])
    tm = no(nt, "ShaderNodeMix", -50, 250, data_type="RGBA", blend_type="MULTIPLY"); tm.inputs["Factor"].default_value = 0.12
    L.new(base, tm.inputs[6]); L.new(tr.outputs["Color"], tm.inputs[7]); base = tm.outputs[2]
    if faixa:
        # faixa bordada (fio de ouro desbotado) numa altura fixa
        z0, z1, cor_f = faixa
        fa = no(nt, "ShaderNodeMapRange", -700, -500); fa.inputs["From Min"].default_value = z0; fa.inputs["From Max"].default_value = z1
        L.new(sep.outputs["Z"], fa.inputs["Value"])
        fr = rampa(nt, [(0.0, "#000000"), (0.08, "#ffffff"), (0.92, "#ffffff"), (1.0, "#000000")], -500, -500, "CONSTANT")
        L.new(fa.outputs["Result"], fr.inputs[0])
        mr = rampa(nt, [(0.0, "#000000"), (0.12, "#ffffff"), (0.26, "#000000"), (0.74, "#ffffff"), (0.88, "#000000")], -500, -750, "CONSTANT")
        L.new(fa.outputs["Result"], mr.inputs[0])
        mul = no(nt, "ShaderNodeMath", -300, -600, operation="MULTIPLY")
        L.new(fr.outputs[0], mul.inputs[0]); L.new(mr.outputs[0], mul.inputs[1])
        mul2 = no(nt, "ShaderNodeMath", -150, -600, operation="MULTIPLY"); mul2.inputs[1].default_value = 0.8
        L.new(mul.outputs[0], mul2.inputs[0])
        fm = no(nt, "ShaderNodeMix", 150, 250, data_type="RGBA")
        L.new(mul2.outputs[0], fm.inputs["Factor"]); L.new(base, fm.inputs[6]); fm.inputs[7].default_value = hexa(cor_f)
        base = fm.outputs[2]
    # dobras e cantos: oclusão escurece e puxa para o violeta
    ao = no(nt, "ShaderNodeAmbientOcclusion", -250, -250); ao.samples = 16; ao.inputs["Distance"].default_value = 0.25
    ar = rampa(nt, [(0.2, "#3a2c55"), (0.95, "#ffffff")], 0, -250)
    L.new(ao.outputs["AO"], ar.inputs[0])
    am = no(nt, "ShaderNodeMix", 350, 250, data_type="RGBA", blend_type="MULTIPLY"); am.inputs["Factor"].default_value = ao_forca
    L.new(base, am.inputs[6]); L.new(ar.outputs[0], am.inputs[7]); base = am.outputs[2]
    em = no(nt, "ShaderNodeEmission", 800, 100); L.new(base, em.inputs["Color"])
    bs = no(nt, "ShaderNodeBsdfPrincipled", 800, -200); L.new(base, bs.inputs["Base Color"]); bs.inputs["Roughness"].default_value = 0.8
    # para a prévia em Cycles usamos o BSDF; para assar, o Emission (trocado em assar())
    L.new(bs.outputs[0], out.inputs[0])
    m["emissao"] = em.name; m["bsdf"] = bs.name
    return m

def materiais(tipo):
    pal = {"saqueador": ("#2e3a66", "#161c3a", "#06070f", "#8a7a4a"),
           "atirador": ("#4a2c78", "#26163f", "#0c0716", "#a07ac0")}[tipo]
    M = {}
    M["manto"] = mat_pintado("manto", pal[0], pal[1], pal[2], faixa=(0.1, 0.19, pal[3]))
    M["capa"] = mat_pintado("capa", pal[0], pal[1], pal[2])
    M["capuz"] = mat_pintado("capuz", pal[0], pal[1], pal[1])
    M["vazio"] = mat_pintado("vazio", "#050308", "#020104", "#000000", ao_forca=0.0)
    M["osso"] = mat_pintado("osso", "#e6dcc2", "#b8a888", "#8a7a64", escala_tecido=60.0)
    M["mascara"] = mat_pintado("mascara", "#cfc4a8", "#9a8c70", "#6a5e4c", escala_tecido=80.0)
    M["ferro"] = mat_pintado("ferro", "#5a5866", "#2a2830", "#1a1820", escala_tecido=90.0)
    M["corda"] = mat_pintado("corda", "#8a6a48", "#5a4430", "#3a2a1e", escala_tecido=120.0)
    return M

# ------------------------------------------------------------------ formas
def torno(nome, perfil, seg, mat, desloc=None, rasgos=None):
    """Superfície de revolução em torno de Z. perfil: [(z, raio_x, raio_y)] de baixo para cima.
    desloc(theta, z) -> (dx, dr) e rasgos: função (i_seg, i_anel) -> True para apagar a face."""
    bm = bmesh.new()
    aneis = []
    for k, (z, rx, ry) in enumerate(perfil):
        anel = []
        for i in range(seg):
            th = i / seg * math.tau
            dx, dr = desloc(th, z) if desloc else (0.0, 0.0)
            anel.append(bm.verts.new(((rx + dr) * math.cos(th) + dx, (ry + dr) * math.sin(th), z)))
        aneis.append(anel)
    for k in range(len(aneis) - 1):
        for i in range(seg):
            if rasgos and rasgos(i, k):
                continue
            a, b = aneis[k][i], aneis[k][(i + 1) % seg]
            c, d = aneis[k + 1][(i + 1) % seg], aneis[k + 1][i]
            bm.faces.new([a, b, c, d])
    vs = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=vs, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    ob = obj_de_bm(nome, bm, mat); suave(ob)
    return ob

def elipsoide(nome, c, r, mat, sub=3):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=1.0)
    for v in bm.verts:
        v.co = Vector((c[0] + v.co.x * r[0], c[1] + v.co.y * r[1], c[2] + v.co.z * r[2]))
    ob = obj_de_bm(nome, bm, mat); suave(ob)
    return ob

def tubo(nome, a, b, ra, rb, mat, seg=10):
    """Cone/cilindro entre dois pontos."""
    a = Vector(a); b = Vector(b)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=ra, radius2=rb, depth=(b - a).length)
    ob = obj_de_bm(nome, bm, mat); suave(ob)
    d = (b - a).normalized()
    q = Vector((0, 0, 1)).rotation_difference(d)
    ob.matrix_world = Matrix.Translation((a + b) / 2) @ q.to_matrix().to_4x4()
    aplicar(ob)
    return ob

def aplicar(ob):
    me = ob.data
    me.transform(ob.matrix_basis.copy() if ob.parent is None else ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)

def solidificar(ob, esp):
    m = ob.modifiers.new("sol", "SOLIDIFY"); m.thickness = esp; m.offset = 0.0
    aplicar_mods(ob)

def aplicar_mods(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    ob.modifiers.clear()
    velho = ob.data
    ob.data = me
    bpy.data.meshes.remove(velho)

# ------------------------------------------------------------------ o espectro
OSSOS = {
    # nome: (cabeça, cauda, pai)
    "raiz": ((0, 0, 0.0), (0, 0, 0.25), None),
    "quadril": ((0, 0, 0.5), (0, 0, 0.88), "raiz"),
    "peito": ((0, 0, 0.88), (0.0, 0, 1.22), "quadril"),
    "cabeca": ((0.02, 0, 1.24), (0.06, 0, 1.62), "peito"),
    "barra_f1": ((0.1, 0, 0.5), (0.16, 0, 0.18), "quadril"),
    "barra_f2": ((0.16, 0, 0.18), (0.2, 0, -0.2), "barra_f1"),
    "barra_t1": ((-0.1, 0, 0.5), (-0.2, 0, 0.18), "quadril"),
    "barra_t2": ((-0.2, 0, 0.18), (-0.32, 0, -0.25), "barra_t1"),
}
for s, y in (("L", 1), ("R", -1)):
    OSSOS.update({
        f"ombro.{s}": ((0, 0.1 * y, 1.17), (0, 0.24 * y, 1.15), "peito"),
        f"braco.{s}": ((0, 0.24 * y, 1.15), (0.03, 0.29 * y, 0.8), f"ombro.{s}"),
        f"antebraco.{s}": ((0.03, 0.29 * y, 0.8), (0.07, 0.3 * y, 0.5), f"braco.{s}"),
        f"mao.{s}": ((0.07, 0.3 * y, 0.5), (0.08, 0.3 * y, 0.4), f"antebraco.{s}"),
        f"dedos.{s}": ((0.08, 0.3 * y, 0.4), (0.09, 0.3 * y, 0.24), f"mao.{s}"),
    })

def P(n, k=0):
    return Vector(OSSOS[n][k])

def construir(M):
    pecas = []
    # --- manto: corpo que afina para cima, dobras verticais, barra puxada para trás e rasgada em tiras
    seg = 56
    perfil = []
    for k in range(17):
        z = -0.32 + k * (1.24 + 0.32) / 16
        t = (z + 0.32) / 1.56
        r = 0.33 - 0.16 * t + 0.02 * math.sin(t * 3.0)
        if z > 1.05: r -= (z - 1.05) * 0.75
        perfil.append((z, r * 1.06, r * 0.92))
    corte = {}
    for i in range(seg):
        # tiras: cada fatia termina numa altura diferente; algumas vão até o fim
        corte[i] = random.choice([0, 0, 1, 2, 3, 4, 5])
    def desloc(th, z):
        t = max(0.0, (0.95 - z) / 1.27)
        dobra = 0.03 * math.sin(th * 9.0 + 1.3) * t + 0.015 * math.sin(th * 23.0) * t
        return (-0.2 * t * t, dobra)
    def rasgos(i, k):
        return k < corte[i]
    manto = torno("manto", perfil, seg, M["manto"], desloc, rasgos)
    # afina a ponta de cada tira
    me = manto.data
    for v in me.vertices:
        if v.co.z < 0.0:
            v.co.z += random.uniform(-0.06, 0.03)
    solidificar(manto, 0.012)
    pecas.append(manto)
    # --- capa curta (mozeta) nos ombros com borda em pontas
    perfil_c = [(0.92, 0.29, 0.27), (1.02, 0.27, 0.25), (1.12, 0.23, 0.22), (1.22, 0.15, 0.15), (1.27, 0.09, 0.09)]
    def desl_c(th, z):
        return (-0.03, 0.012 * math.sin(th * 7.0))
    capa = torno("capa", perfil_c, 40, M["capa"], desl_c)
    for v in capa.data.vertices:
        if v.co.z < 0.92:
            th = math.atan2(v.co.y, v.co.x)
            v.co.z -= 0.07 * abs(math.sin(th * 5.0)) + random.uniform(0, 0.03)
    solidificar(capa, 0.014)
    pecas.append(capa)
    # --- capuz: esfera esticada com ponta caída para trás e a abertura do rosto
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=28, v_segments=18, radius=1.0)
    cen = Vector((0.03, 0, 1.42))
    for v in bm.verts:
        p = v.co.copy()
        q = Vector((p.x * 0.25, p.y * 0.21, p.z * 0.25))
        # aba da frente avança sobre o rosto (deixa a máscara na sombra)
        if p.x > 0.2 and p.z > 0.1:
            k = min(1.0, (p.x - 0.2) * 1.4) * min(1.0, (p.z - 0.1) * 1.6)
            q += Vector((0.09 * k, 0, -0.03 * k))
        # ponta curta caída para trás
        if p.z > 0.25 and p.x < 0.1:
            k = (p.z - 0.25) * (0.1 - p.x)
            q += Vector((-0.34 * k, 0, 0.2 * k)) * (1.0 - abs(p.y) * 0.8)
        # laterais descem até os ombros
        if p.z < -0.3:
            q.y *= 1.0 + (-p.z - 0.3) * 0.5
        v.co = cen + q
    rosto = [f for f in bm.faces if all((v.co.x - cen.x) > 0.12 and abs(v.co.y) < 0.13 and abs(v.co.z - 1.38) < 0.17 for v in f.verts)]
    bmesh.ops.delete(bm, geom=rosto, context="FACES")
    capuz = obj_de_bm("capuz", bm, M["capuz"]); suave(capuz)
    solidificar(capuz, 0.02)
    pecas.append(capuz)
    vazio = elipsoide("vazio", (0.04, 0, 1.41), (0.17, 0.165, 0.2), M["vazio"])
    pecas.append(vazio)
    # --- máscara de osso rachada dentro do capuz, com olhos fundos
    mask = elipsoide("mascara", (0.13, 0, 1.38), (0.075, 0.09, 0.16), M["mascara"])
    for v in mask.data.vertices:
        if v.co.x < 0.13: v.co.x = 0.13 + (v.co.x - 0.13) * 0.3
        if v.co.z < 1.36:  # queixo comprido e afilado
            k = (1.36 - v.co.z) / 0.14
            v.co.y *= 1.0 - 0.55 * k; v.co.z -= 0.05 * k
        if v.co.z > 1.43 and abs(v.co.y) < 0.08:  # arco da sobrancelha
            v.co.x += 0.012
    pecas.append(mask)
    for y in (0.045, -0.045):
        o = elipsoide(f"orbita{y}", (0, 0, 0), (0.022, 0.03, 0.012), M["vazio"])
        o.rotation_euler = (0.45 * (1 if y > 0 else -1), 0, 0); o.location = (0.205, y, 1.42); aplicar(o)
        pecas.append(o)
    rachadura = tubo("rachadura", (0.222, 0.022, 1.49), (0.226, 0.005, 1.33), 0.004, 0.003, M["vazio"], 4)
    pecas.append(rachadura)
    # --- braços: manga larga rasgada, antebraço de osso e mão com garras
    for s, y in (("L", 1), ("R", -1)):
        perfil_m = [(0.0, 0.16, 0.15), (0.12, 0.12, 0.11), (0.3, 0.085, 0.08), (0.4, 0.07, 0.07)]
        manga = torno(f"manga.{s}", perfil_m, 24, M["capa"], lambda th, z: (0.0, 0.01 * math.sin(th * 5)))
        for v in manga.data.vertices:
            if v.co.z < 0.01:
                th = math.atan2(v.co.y, v.co.x)
                v.co.z -= 0.08 * abs(math.sin(th * 3.0 + y)) + random.uniform(0, 0.03)
        solidificar(manga, 0.01)
        # posiciona a manga do ombro até o meio do antebraço (abre para baixo)
        a, b = P(f"braco.{s}"), P(f"antebraco.{s}", 1) * 0.35 + P(f"antebraco.{s}") * 0.65
        d = (a - b).normalized()
        q = Vector((0, 0, 1)).rotation_difference(d)
        escala = (a - b).length / 0.4
        manga.matrix_world = Matrix.Translation(b) @ q.to_matrix().to_4x4() @ Matrix.Diagonal((1, 1, escala, 1))
        aplicar(manga)
        pecas.append(manga)
        ante = tubo(f"ante.{s}", P(f"antebraco.{s}"), P(f"mao.{s}"), 0.028, 0.022, M["osso"], 8)
        pulso = elipsoide(f"pulso.{s}", P(f"mao.{s}"), (0.03, 0.03, 0.03), M["osso"])
        palma = elipsoide(f"palma.{s}", (P(f"mao.{s}") + P(f"mao.{s}", 1)) / 2, (0.045, 0.03, 0.06), M["osso"])
        pecas += [ante, pulso, palma]
        base = P(f"dedos.{s}")
        for j, (dx, dy) in enumerate(((0.03, 0.02), (0.012, 0.03), (-0.008, 0.03), (-0.03, 0.018))):
            p0 = base + Vector((dx, dy * y * 0.6, 0))
            p1 = p0 + Vector((0.025, 0.004 * y, -0.075))
            p2 = p1 + Vector((0.035, 0.0, -0.06))
            p3 = p2 + Vector((0.035, 0.0, -0.02))
            pecas.append(tubo(f"dedo{j}a.{s}", p0, p1, 0.011, 0.009, M["osso"], 6))
            pecas.append(tubo(f"dedo{j}b.{s}", p1, p2, 0.009, 0.007, M["osso"], 6))
            pecas.append(tubo(f"garra{j}.{s}", p2, p3, 0.007, 0.0005, M["ferro"], 6))
        if s == "L":
            # algema quebrada no pulso com três elos pendurados
            alg = torno("algema", [(-0.025, 0.045, 0.045), (0.025, 0.045, 0.045)], 16, M["ferro"])
            solidificar(alg, 0.012)
            alg.location = P("mao.L") + Vector((-0.01, 0, 0.04)); aplicar(alg)
            pecas.append(alg)
            elo_p = P("mao.L") + Vector((-0.03, 0.0, 0.0))
            for k in range(3):
                e = torno(f"elo{k}", [(-0.006, 0.022, 0.012), (0.006, 0.022, 0.012)], 10, M["ferro"])
                solidificar(e, 0.008)
                e.rotation_euler = (math.pi / 2, 0, (k % 2) * math.pi / 2)
                e.location = elo_p + Vector((-0.01 * k, 0, -0.04 * k)); aplicar(e)
                pecas.append(e)
    # --- cordão de monge na cintura com contas e um medalhão partido
    cord = torno("cordao", [(-0.012, 0.235, 0.205), (0.012, 0.235, 0.205)], 32, M["corda"])
    solidificar(cord, 0.025)
    cord.rotation_euler = (0, 0.12, 0); cord.location = (-0.03, 0, 0.84); aplicar(cord)
    pecas.append(cord)
    for k in range(9):
        z = 0.8 - k * 0.045
        conta = elipsoide(f"conta{k}", (0.215 + 0.006 * k, 0.05, z), (0.018, 0.018, 0.018), M["osso"])
        pecas.append(conta)
    med = torno("medalhao", [(-0.008, 0.045, 0.045), (0.008, 0.045, 0.045)], 8, M["ferro"])
    solidificar(med, 0.01)
    med.rotation_euler = (0, math.pi / 2, 0.3); med.location = (0.275, 0.05, 0.39); aplicar(med)
    pecas.append(med)
    return pecas

def pesos(pecas):
    """Cada peça rígida vai inteira para um osso; manto e capa recebem pesos suaves."""
    def mais_perto(p):
        melhor, dmin = None, 9
        for n, (a, b, _) in OSSOS.items():
            if n in ("raiz",): continue
            a = Vector(a); b = Vector(b); ab = b - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
            d = (a + ab * t - p).length
            if d < dmin: melhor, dmin = n, d
        return melhor
    for ob in pecas:
        n = ob.name
        if n in ("manto",):
            vgs = {k: ob.vertex_groups.new(name=k) for k in ("quadril", "peito", "barra_f1", "barra_f2", "barra_t1", "barra_t2")}
            for v in ob.data.vertices:
                z = v.co.z
                frente = max(0.0, min(1.0, 0.5 + v.co.x * 1.6))
                w = {}
                if z > 0.9:
                    w["peito"] = 1.0
                elif z > 0.55:
                    k = (z - 0.55) / 0.35; w["peito"] = k; w["quadril"] = 1 - k
                elif z > 0.18:
                    k = (z - 0.18) / 0.37
                    w["quadril"] = k; w["barra_f1"] = (1 - k) * frente; w["barra_t1"] = (1 - k) * (1 - frente)
                else:
                    k = max(0.0, min(1.0, (z + 0.25) / 0.43))
                    w["barra_f1"] = k * frente; w["barra_t1"] = k * (1 - frente)
                    w["barra_f2"] = (1 - k) * frente; w["barra_t2"] = (1 - k) * (1 - frente)
                for g, p in w.items():
                    if p > 0.001: vgs[g].add([v.index], p, "REPLACE")
        elif n == "capa":
            vgs = {k: ob.vertex_groups.new(name=k) for k in ("peito", "ombro.L", "ombro.R")}
            for v in ob.data.vertices:
                lado = max(0.0, min(1.0, abs(v.co.y) / 0.3)) * 0.5
                vgs["peito"].add([v.index], 1 - lado, "REPLACE")
                vgs["ombro.L" if v.co.y > 0 else "ombro.R"].add([v.index], lado, "REPLACE")
        elif n.startswith("manga."):
            s = n[-1]
            vgs = {k: ob.vertex_groups.new(name=k) for k in (f"braco.{s}", f"antebraco.{s}")}
            a = P(f"braco.{s}"); b = P(f"antebraco.{s}", 1)
            for v in ob.data.vertices:
                t = max(0.0, min(1.0, (v.co - a).dot(b - a) / (b - a).length_squared))
                k = max(0.0, min(1.0, (t - 0.35) / 0.3))
                vgs[f"braco.{s}"].add([v.index], 1 - k, "REPLACE")
                vgs[f"antebraco.{s}"].add([v.index], k, "REPLACE")
        elif n.startswith(("capuz", "vazio", "mascara", "orbita", "rachadura")):
            grupo(ob, "cabeca")
        elif n.startswith(("cordao", "conta", "medalhao")):
            grupo(ob, "quadril")
        elif n.startswith(("dedo", "garra")):
            grupo(ob, f"dedos.{n[-1]}")
        elif n.startswith(("palma", "pulso", "algema", "elo")):
            grupo(ob, "mao.L" if n.startswith(("algema", "elo")) else f"mao.{n[-1]}")
        elif n.startswith("ante."):
            grupo(ob, f"antebraco.{n[-1]}")
        else:
            c = sum((v.co for v in ob.data.vertices), Vector()) / len(ob.data.vertices)
            grupo(ob, mais_perto(c))

def esqueleto():
    arm = bpy.data.armatures.new("esqueleto")
    ob = bpy.data.objects.new("espectro", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    for n, (a, b, pai) in OSSOS.items():
        e = arm.edit_bones.new(n); e.head = a; e.tail = b
        e.roll = 0.0
        if pai: e.parent = arm.edit_bones[pai]; e.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in ob.pose.bones: pb.rotation_mode = "XYZ"
    return ob

def juntar(pecas, arm):
    bpy.ops.object.select_all(action="DESELECT")
    for p in pecas: p.select_set(True)
    bpy.context.view_layer.objects.active = pecas[0]
    bpy.ops.object.join()
    corpo = bpy.context.view_layer.objects.active
    corpo.name = "corpo"
    corpo.parent = arm
    md = corpo.modifiers.new("arm", "ARMATURE"); md.object = arm
    return corpo

# ------------------------------------------------------------------ animação
def rot_mundo(arm, osso, eixo, ang):
    """Rotação local do osso que equivale a girar 'ang' em torno de um eixo do espaço do boneco."""
    rest = arm.data.bones[osso].matrix_local.to_3x3()
    R = Matrix.Rotation(ang, 3, Vector(eixo))
    loc = rest.inverted() @ R @ rest
    return loc.to_euler("XYZ")

def pose(arm, quadro, P_):
    """P_: {osso: [(eixo, ang), ...] ou ('loc', (x,y,z))}. Ossos sem entrada voltam ao repouso."""
    for pb in arm.pose.bones:
        spec = P_.get(pb.name, [])
        R = Matrix.Identity(3)
        loc = Vector()
        for item in spec:
            if item[0] == "loc":
                loc = Vector(item[1])
            else:
                R = Matrix.Rotation(item[1], 3, Vector(item[0])) @ R
        rest = arm.data.bones[pb.name].matrix_local.to_3x3()
        pb.rotation_euler = (rest.inverted() @ R @ rest).to_euler("XYZ")
        pb.location = rest.inverted() @ loc
        pb.keyframe_insert("rotation_euler", frame=quadro)
        pb.keyframe_insert("location", frame=quadro)

Y = (0, 1, 0); X = (1, 0, 0); Z = (0, 0, 1)

def p_base(t, onda=1.0, sobe=0.0, incl=0.0, bracos=0.0):
    """Pose de flutuar: 't' em 0..1 dá a fase do ciclo."""
    s = math.sin(t * math.tau); c = math.cos(t * math.tau)
    return {
        "raiz": [("loc", (0, 0, 0.04 * s * onda + sobe))],
        "quadril": [(Y, incl * 0.5 + 0.03 * c * onda)],
        "peito": [(Y, incl * 0.5 + 0.04 * s * onda), (X, 0.03 * c * onda)],
        "cabeca": [(Y, 0.1 - 0.06 * s * onda), (X, 0.04 * c * onda)],
        "barra_f1": [(Y, -0.08 * c * onda), (X, 0.06 * s * onda)],
        "barra_f2": [(Y, -0.12 * math.cos(t * math.tau - 0.8) * onda)],
        "barra_t1": [(Y, 0.1 + 0.1 * c * onda), (X, -0.06 * s * onda)],
        "barra_t2": [(Y, 0.15 + 0.16 * math.cos(t * math.tau - 0.8) * onda)],
        "braco.L": [(Y, -0.15 + 0.08 * s * onda + bracos), (X, -0.12)],
        "antebraco.L": [(Y, -0.35 + 0.06 * c * onda)],
        "dedos.L": [(Y, -0.3 + 0.1 * s)],
        "braco.R": [(Y, -0.1 - 0.08 * s * onda + bracos), (X, 0.12)],
        "antebraco.R": [(Y, -0.3 - 0.06 * c * onda)],
        "dedos.R": [(Y, -0.3 - 0.1 * s)],
    }

def acao(arm, nome, quadros, fn, ciclo=False):
    a = bpy.data.actions.new(nome)
    arm.animation_data_create(); arm.animation_data.action = a
    for f in quadros:
        pose(arm, f, fn(f))
    for fc in getattr(a, "fcurves", []):
        for k in fc.keyframe_points: k.interpolation = "BEZIER"
    a.use_fake_user = True
    # guarda como faixa NLA para o exportador gerar uma animação por ação
    tr = arm.animation_data.nla_tracks.new(); tr.name = nome
    st = tr.strips.new(nome, int(quadros[0]), a); st.name = nome
    arm.animation_data.action = None
    return a

def misturar(a, b, k):
    out = {}
    for n in set(a) | set(b):
        la = dict((("loc" if i[0] == "loc" else tuple(i[0])), i[1]) for i in a.get(n, []))
        lb = dict((("loc" if i[0] == "loc" else tuple(i[0])), i[1]) for i in b.get(n, []))
        lst = []
        for key in set(la) | set(lb):
            if key == "loc":
                va = Vector(la.get(key, (0, 0, 0))); vb = Vector(lb.get(key, (0, 0, 0)))
                lst.append(("loc", tuple(va.lerp(vb, k))))
            else:
                lst.append((key, la.get(key, 0.0) * (1 - k) + lb.get(key, 0.0) * k))
        out[n] = lst
    return out

def p_preparo(tremor=0.0):
    b = p_base(0.25, 0.3, sobe=0.1, incl=-0.3)
    b.update({
        "cabeca": [(Y, 0.35 + tremor * 0.03)],
        "braco.R": [(Y, 2.5), (X, 0.35)],
        "antebraco.R": [(Y, 0.9)],
        "dedos.R": [(Y, 0.55 + tremor * 0.05)],
        "braco.L": [(Y, -1.0), (X, -0.3)],
        "antebraco.L": [(Y, -0.5)],
        "dedos.L": [(Y, 0.4)],
        "barra_t1": [(Y, -0.1)], "barra_t2": [(Y, -0.15)],
        "barra_f1": [(Y, 0.15)], "barra_f2": [(Y, 0.25)],
    })
    return b

def p_golpe_fim():
    b = p_base(0.0, 0.0, sobe=-0.04, incl=0.5)
    b["raiz"] = [("loc", (0.16, 0, -0.04))]
    b.update({
        "cabeca": [(Y, 0.05)],
        "braco.R": [(Y, -1.35), (X, 0.25)],
        "antebraco.R": [(Y, -0.6)],
        "dedos.R": [(Y, -0.7)],
        "braco.L": [(Y, 0.6), (X, -0.2)],
        "antebraco.L": [(Y, -0.4)],
        "barra_t1": [(Y, 0.45)], "barra_t2": [(Y, 0.6)],
        "barra_f1": [(Y, 0.3)], "barra_f2": [(Y, 0.35)],
    })
    return b

def animar(arm):
    acao(arm, "parado", list(range(0, 61, 5)), lambda f: p_base(f / 60.0), True)
    def flutua(f):
        t = f / 36.0
        b = p_base(t, 1.3, incl=0.32, bracos=0.45)
        b["barra_t1"] = [(Y, 0.45 + 0.12 * math.cos(t * math.tau))]
        b["barra_t2"] = [(Y, 0.6 + 0.2 * math.cos(t * math.tau - 1.0))]
        b["barra_f1"] = [(Y, 0.3 + 0.1 * math.cos(t * math.tau))]
        b["barra_f2"] = [(Y, 0.35 + 0.15 * math.cos(t * math.tau - 1.0))]
        return b
    acao(arm, "andar", list(range(0, 37, 4)), flutua, True)
    acao(arm, "preparo", [0, 4, 8, 12, 16], lambda f: p_preparo((f // 4) % 2))
    def golpe(f):
        if f <= 0: return p_preparo()
        if f <= 4: return misturar(p_preparo(), p_golpe_fim(), (f / 4.0) ** 0.6)
        if f <= 14: return misturar(p_golpe_fim(), p_golpe_fim(), 0)
        return misturar(p_golpe_fim(), p_base(0.0), min(1.0, (f - 14) / 10.0))
    acao(arm, "golpe", [0, 1, 2, 3, 4, 8, 14, 19, 24], golpe)
    def dor(f):
        d = p_base(0.0, 0.0, incl=-0.55)
        d.update({"cabeca": [(Y, -0.5)], "braco.R": [(Y, -1.1), (X, 0.5)], "braco.L": [(Y, -0.9), (X, -0.5)],
                  "barra_t1": [(Y, -0.3)], "barra_f1": [(Y, -0.35)], "barra_f2": [(Y, -0.4)], "raiz": [("loc", (-0.08, 0, 0.03))]})
        if f <= 2: return misturar(p_base(0.0), d, f / 2.0)
        return misturar(d, p_base(0.0), (f - 2) / 10.0)
    acao(arm, "dor", [0, 1, 2, 5, 8, 12], dor)
    def morte(f):
        k = min(1.0, f / 30.0)
        d = p_base(0.0, 0.0, incl=-0.4 + 1.2 * k)
        d["raiz"] = [("loc", (0, 0, -0.55 * k * k))]
        d.update({"cabeca": [(Y, -0.6 + 1.4 * k)], "braco.R": [(Y, -1.6 * (1 - k)), (X, 0.6)], "braco.L": [(Y, -1.3 * (1 - k)), (X, -0.6)],
                  "barra_t1": [(Y, -0.4 + 1.0 * k)], "barra_f1": [(Y, -0.5 + 1.2 * k)]})
        return d
    acao(arm, "morte", [0, 4, 8, 14, 20, 26, 30, 40], morte)

# ------------------------------------------------------------------ prévia, texturas e exportação
def config(sc, larg=640, alt=640, amostras=24):
    sc.render.engine = "CYCLES"; sc.cycles.samples = amostras; sc.cycles.use_denoising = True
    sc.render.resolution_x = larg; sc.render.resolution_y = alt
    sc.view_settings.view_transform = "AgX"
    sc.render.fps = FPS
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = hexa("#20243a"); w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    for n, (rot, e, c) in {"chave": ((0.9, 0.2, 0.6), 4.0, "#ffffff"), "contra": ((-0.9, 0.0, 2.8), 6.0, "#9fb4ff")}.items():
        l = bpy.data.lights.new(n, "SUN"); l.energy = e; l.color = hexa(c)[:3]
        o = bpy.data.objects.new(n, l); sc.collection.objects.link(o); o.rotation_euler = rot
    cd = bpy.data.cameras.new("cam"); cd.type = "ORTHO"; cd.ortho_scale = 2.4
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam)
    # vista de lado, um pouco de frente (como no jogo, girado 0.35 rad para a câmera)
    cam.location = (1.2, -5.0, 0.8); cam.rotation_euler = (math.radians(90), 0, math.radians(14))
    sc.camera = cam

def assar(corpo, M, tam=1024):
    """Desdobra o UV e assa a pintura procedural (com oclusão) numa textura só."""
    bpy.context.view_layer.objects.active = corpo
    bpy.ops.object.select_all(action="DESELECT"); corpo.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    img = bpy.data.images.new("espectro_tex", tam, tam, alpha=False)
    for m in corpo.data.materials:
        nt = m.node_tree
        it = nt.nodes.new("ShaderNodeTexImage"); it.image = img
        nt.nodes.active = it
        out = [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]
        nt.links.new(nt.nodes[m["emissao"]].outputs[0], out.inputs[0])
    sc = bpy.context.scene
    sc.cycles.samples = 64
    sc.cycles.bake_type = "EMIT"
    sc.render.bake.margin = 6
    bpy.ops.object.bake(type="EMIT")
    return img

def montar(tipo="saqueador"):
    sc = limpar()
    M = materiais(tipo)
    pecas = construir(M)
    pesos(pecas)
    arm = esqueleto()
    corpo = juntar(pecas, arm)
    # olhos e alma: pontos de encaixe para os brilhos no Godot
    for nome, osso, p in (("olho0", "cabeca", (0.225, 0.045, 1.41)), ("olho1", "cabeca", (0.225, -0.045, 1.41)),
                          ("alma", "peito", (0.12, 0, 1.0)), ("garraR", "dedos.R", (0.13, -0.3, 0.2)), ("garraL", "dedos.L", (0.13, 0.3, 0.2))):
        e = bpy.data.objects.new(nome, None); sc.collection.objects.link(e)
        e.parent = arm; e.parent_type = "BONE"; e.parent_bone = osso
        b = arm.data.bones[osso]
        e.matrix_world = Matrix.Translation(p)
    animar(arm)
    return sc, arm, corpo, M

if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    modo = args[0] if args else "previa"
    tipo = os.environ.get("TIPO", "saqueador")
    sc, arm, corpo, M = montar(tipo)
    if modo == "previa":
        destino = os.environ.get("PREVIA_DIR", "/tmp")
        config(sc, amostras=int(os.environ.get("AMOSTRAS", "16")))
        pares = args[1:] or ["parado", "0"]
        for i in range(0, len(pares), 2):
            nome, q = pares[i], int(pares[i + 1])
            arm.animation_data.action = bpy.data.actions[nome]
            for tr in arm.animation_data.nla_tracks: tr.mute = True
            sc.frame_set(q)
            sc.render.filepath = os.path.join(destino, f"esp_{nome}_{q}.png")
            bpy.ops.render.render(write_still=True)
    elif modo == "exportar":
        config(sc)
        img = assar(corpo, M, 1024)
        img.filepath_raw = os.path.join(SAIDA, f"espectro_novo_{tipo}.png"); img.file_format = "PNG"; img.save()
        # material final só com a textura (o Godot troca pelo shader anime)
        mat = bpy.data.materials.new("espectro"); mat.use_nodes = True
        bs = mat.node_tree.nodes["Principled BSDF"]
        it = mat.node_tree.nodes.new("ShaderNodeTexImage"); it.image = img
        mat.node_tree.links.new(it.outputs[0], bs.inputs["Base Color"])
        corpo.data.materials.clear(); corpo.data.materials.append(mat)
        bpy.ops.object.select_all(action="DESELECT")
        arm.select_set(True); corpo.select_set(True)
        for o in sc.objects:
            if o.type == "EMPTY": o.select_set(True)
        if tipo == "saqueador":
            bpy.ops.export_scene.gltf(filepath=os.path.join(SAIDA, "espectro_novo.glb"), export_format="GLB",
                                      use_selection=True, export_animations=True, export_animation_mode="NLA_TRACKS",
                                      export_image_format="NONE", export_materials="PLACEHOLDER", export_yup=True)
