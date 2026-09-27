// Classes do jogo. Isso é dado de design, não lógica — cada classe pode
// ganhar sua própria fórmula de dano/skills depois; por ora todas usam
// a mesma fórmula base de combate (ver game/combat.ts).
export const CHARACTER_CLASSES = [
  "guerreiro_1m", // guerreiro de uma espada
  "guerreiro_2m", // guerreiro de duas espadas
  "mago_cajado_escudo",
  "mago_cajado_2m",
  "arqueiro_arco",
  "arqueiro_besta",
  "imperador", // cavalo + maça + escudo
  "elfa", // suporte: healer/buffer
  "guerreiro_mago", // espada com magia em área
  "fighter", // manoplas
  "assassino", // adaga
] as const;

export type CharacterClass = (typeof CHARACTER_CLASSES)[number];

export function isValidClass(value: string): value is CharacterClass {
  return (CHARACTER_CLASSES as readonly string[]).includes(value);
}
