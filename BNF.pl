:- encoding(utf8).

% =============================================================
% BNF.pl - Gramática libre de contexto e interpretación
% OrientadorCE - Taller 3 Prolog (CE1106)
% Persona 2: Gramática e interpretación
%
% Este archivo NO se consulta directamente: Logic.pl lo carga con
% ensure_loaded/1. El predicado que usa Logic.pl es:
%
%   interpretar(+Texto, -Preferencias)
%
%     Texto         : string (o átomo) con la frase del usuario.
%     Preferencias  : lista con elementos gusta(Interes) o
%                     no_gusta(Interes). Si la frase no pertenece
%                     al lenguaje de la gramática, interpretar/2 FALLA
%                     (así Logic.pl pide reformular y no registra nada).
%
% La gramática se describe en BNF en el bloque siguiente; su
% implementación usa DCG (-->) que es justamente la forma de escribir
% gramáticas libres de contexto en Prolog.
% =============================================================

% -------------------------------------------------------------
% GRAMÁTICA (BNF)
% -------------------------------------------------------------
%
% <oracion>   ::= <clausula> | <clausula> <conector> <oracion>
% <conector>  ::= "y" | "tambien"
%
% <clausula>  ::= "no" <clausula_afirmativa>     % negación con "no"
%               | <clausula_negativa>            % verbos negativos
%               | <clausula_afirmativa>
%
% <clausula_afirmativa> ::= <afirmador> <sujeto> <predicado_pos> <complementos>
%                         | <complementos>                 % frase nominal suelta
% <clausula_negativa>   ::= <sujeto> <predicado_neg> <complementos>
%
% <afirmador> ::= "si" | "claro" | "por supuesto" | <vacio>
% <sujeto>    ::= "yo" | "a mi" | <vacio>
%
% <predicado_pos> ::= "me gusta" | "me gustan" | "me interesa" |
%                     "me interesan" | "me encanta" | "me encantan" |
%                     "me agrada" | "me agradan" | "me apasiona" |
%                     "me llama la atencion" | "disfruto" | "disfruto de" |
%                     "prefiero" | "quiero" | "tengo interes en" |
%                     "me considero" | "soy bueno en" | "soy buena en" | ...
%
% <predicado_neg> ::= "me disgusta" | "me disgustan" | "odio" |
%                     "detesto" | "aborrezco" | "no soporto" | "evito" | ...
%
% <complementos> ::= <complemento> | <complemento> <conector> <complementos>
% <complemento>  ::= <intensificador> <locucion> <articulo> <nucleo>
% <intensificador> ::= "mucho" | "bastante" | "demasiado" | <vacio>
% <locucion>       ::= "trabajar con" | "trabajar en" | "estudiar" |
%                      "trabajar" | "usar" | "con" | <vacio>
% <articulo>       ::= "el" | "la" | "los" | "las" | "un" | "una" | <vacio>
% <nucleo>         ::= términos que identifican un interés (ver nucleo//2)
%
% Ejemplos admitidos:
%   "Me gustan las matemáticas"          -> [gusta(matematicas)]
%   "Disfruto trabajar con tecnología"   -> [gusta(tecnologia)]
%   "Prefiero escuchar a los demás"      -> [gusta(escuchar)]
%   "No me gusta la tecnología"          -> [no_gusta(tecnologia)]
%   "Me gusta leer y dibujar"            -> [gusta(lectura), gusta(dibujo)]
%   "La ventana está abierta"            -> falla (no se reconoce)
% -------------------------------------------------------------


% -------------------------------------------------------------
% Punto de entrada
% -------------------------------------------------------------

% interpretar(+Texto, -Preferencias)
interpretar(Texto0, Preferencias) :-
    a_string(Texto0, Texto),
    tokenizar(Texto, Tokens),
    Tokens \= [],
    phrase(oracion(Prefs), Tokens),
    Prefs \= [],
    unicos(Prefs, Preferencias).

% Normaliza la entrada a string (por comodidad si llega átomo o lista)
a_string(S, S) :- string(S), !.
a_string(A, S) :- atom(A), !, atom_string(A, S).
a_string(L, S) :- is_list(L), !, string_codes(S, L).


% -------------------------------------------------------------
% Gramática (DCG)
% -------------------------------------------------------------

% <oracion>
oracion(P) -->
    clausula(P1),
    conector,
    oracion(P2),
    { append(P1, P2, P) }.
oracion(P) -->
    clausula(P).

% <conector>
conector --> [y].
conector --> [tambien].

% <clausula>
clausula(P) -->
    [no],
    clausula_afirmativa(P0),
    { negar(P0, P) }.
clausula(P) -->
    clausula_negativa(P).
clausula(P) -->
    clausula_afirmativa(P).

% <clausula_afirmativa>
clausula_afirmativa(P) -->
    afirmador,
    sujeto,
    predicado_pos,
    complementos(P).
clausula_afirmativa(P) -->
    complementos(P).

% <clausula_negativa> (verbos que ya son negativos: odio, detesto, ...)
clausula_negativa(P) -->
    sujeto,
    predicado_neg,
    complementos(P0),
    { negar(P0, P) }.

% <afirmador>
afirmador --> [].
afirmador --> [si].
afirmador --> [claro].
afirmador --> [por, supuesto].

% <sujeto>
sujeto --> [].
sujeto --> [yo].
sujeto --> [a, mi].

% <complementos>
complementos(P) -->
    complemento(P1),
    mas_complementos(P1, P).
mas_complementos(P, P) --> [].
mas_complementos(P1, P) -->
    conector,
    complemento(P2),
    mas_complementos(P2, P3),
    { append(P1, P3, P) }.

% <complemento> -> produce una preferencia gusta/1
complemento([gusta(I)]) -->
    intensificador,
    locucion,
    articulo,
    nucleo(I).

% <intensificador>
intensificador --> [].
intensificador --> [mucho].
intensificador --> [bastante].
intensificador --> [demasiado].

% <locucion>
locucion --> [].
locucion --> [trabajar, con].
locucion --> [trabajar, en].
locucion --> [trabajar].
locucion --> [estudiar].
locucion --> [usar].
locucion --> [con].

% <articulo>
articulo --> [].
articulo --> [el].
articulo --> [la].
articulo --> [los].
articulo --> [las].
articulo --> [un].
articulo --> [una].


% -------------------------------------------------------------
% <predicado_pos>: verbos/expresiones afirmativas
% -------------------------------------------------------------
predicado_pos --> [me, gusta].
predicado_pos --> [me, gustan].
predicado_pos --> [me, gustaria].
predicado_pos --> [me, gustarian].
predicado_pos --> [me, interesa].
predicado_pos --> [me, interesan].
predicado_pos --> [me, encanta].
predicado_pos --> [me, encantan].
predicado_pos --> [me, agrada].
predicado_pos --> [me, agradan].
predicado_pos --> [me, apasiona].
predicado_pos --> [me, apasionan].
predicado_pos --> [me, llama, la, atencion].
predicado_pos --> [me, gusta, aprender].
predicado_pos --> [disfruto].
predicado_pos --> [disfruta].
predicado_pos --> [disfruto, de].
predicado_pos --> [prefiero].
predicado_pos --> [quiero].
predicado_pos --> [tengo, interes, en].
predicado_pos --> [tengo, interes].
predicado_pos --> [me, considero].
predicado_pos --> [soy, bueno, en].
predicado_pos --> [soy, buena, en].
predicado_pos --> [soy, bueno, para].
predicado_pos --> [soy, buena, para].
predicado_pos --> [me, va, bien, con].
predicado_pos --> [me, llevo, bien, con].

% -------------------------------------------------------------
% <predicado_neg>: expresiones negativas (sin la partícula "no",
% que ya se maneja en <clausula>)
% -------------------------------------------------------------
predicado_neg --> [me, disgusta].
predicado_neg --> [me, disgustan].
predicado_neg --> [odio].
predicado_neg --> [detesto].
predicado_neg --> [aborrezco].
predicado_neg --> [no, soporto].
predicado_neg --> [no, tolero].
predicado_neg --> [evito].


% -------------------------------------------------------------
% Utilidades de polaridad
% -------------------------------------------------------------

% negar/2 invierte la polaridad de una lista de preferencias
negar([], []).
negar([P|Ps], [N|Ns]) :-
    negar_uno(P, N),
    negar(Ps, Ns).

negar_uno(gusta(I), no_gusta(I)) :- !.
negar_uno(no_gusta(I), gusta(I)) :- !.
negar_uno(P, P).

% quita preferencias repetidas conservando el orden
unicos([], []).
unicos([X|Xs], [X|Ys]) :-
    \+ memberchk(X, Xs),
    !,
    unicos(Xs, Ys).
unicos([X|Xs], Ys) :-
    memberchk(X, Xs),
    !,
    unicos(Xs, Ys).


% -------------------------------------------------------------
% <nucleo>: léxico de intereses (debe coincidir con BD.pl)
% Cada cláusula mapea una o varias palabras a un interés.
% -------------------------------------------------------------

% matemáticas
nucleo(matematicas) --> [matematicas].
nucleo(matematicas) --> [matematica].
nucleo(matematicas) --> [matematicos].
nucleo(matematicas) --> [numeros].
nucleo(matematicas) --> [calculo].
nucleo(matematicas) --> [algebra].

% tecnología
nucleo(tecnologia) --> [tecnologia].
nucleo(tecnologia) --> [tecnologias].
nucleo(tecnologia) --> [computacion].
nucleo(tecnologia) --> [informatica].
nucleo(tecnologia) --> [computadoras].
nucleo(tecnologia) --> [computadores].
nucleo(tecnologia) --> [computadora].
nucleo(tecnologia) --> [programacion].
nucleo(tecnologia) --> [programar].
nucleo(tecnologia) --> [software].
nucleo(tecnologia) --> [electronica].

% resolver problemas
nucleo(resolver_problemas) --> [resolver].
nucleo(resolver_problemas) --> [problemas].
nucleo(resolver_problemas) --> [resolver, problemas].
nucleo(resolver_problemas) --> [solucionar, problemas].
nucleo(resolver_problemas) --> [pensar].
nucleo(resolver_problemas) --> [retos].
nucleo(resolver_problemas) --> [desafios].
nucleo(resolver_problemas) --> [resolver, retos].

% ayudar a las personas
nucleo(ayudar_personas) --> [ayudar].
nucleo(ayudar_personas) --> [ayudar, personas].
nucleo(ayudar_personas) --> [ayudar, a, personas].
nucleo(ayudar_personas) --> [ayudar, a, las, personas].
nucleo(ayudar_personas) --> [ayudar, a, la, gente].
nucleo(ayudar_personas) --> [ayudar, a, los, demas].
nucleo(ayudar_personas) --> [ayudar, a, otros].
nucleo(ayudar_personas) --> [ayudar, gente].
nucleo(ayudar_personas) --> [servir].
nucleo(ayudar_personas) --> [servir, a, los, demas].
nucleo(ayudar_personas) --> [servir, a, las, personas].
nucleo(ayudar_personas) --> [personas].

% escuchar
nucleo(escuchar) --> [escuchar].
nucleo(escuchar) --> [escuchar, a, los, demas].
nucleo(escuchar) --> [escuchar, a, las, personas].
nucleo(escuchar) --> [escuchar, a, otros].
nucleo(escuchar) --> [escuchar, personas].
nucleo(escuchar) --> [oir].

% empatía
nucleo(empatia) --> [empatia].
nucleo(empatia) --> [empatico].
nucleo(empatia) --> [empatica].
nucleo(empatia) --> [comprender].
nucleo(empatia) --> [comprender, a, los, demas].
nucleo(empatia) --> [comprender, a, las, personas].
nucleo(empatia) --> [comprender, sentimientos].
nucleo(empatia) --> [sentimientos].

% ciencias de la salud
nucleo(ciencias_salud) --> [salud].
nucleo(ciencias_salud) --> [ciencias, de, la, salud].
nucleo(ciencias_salud) --> [ciencia, de, la, salud].
nucleo(ciencias_salud) --> [medicina].
nucleo(ciencias_salud) --> [cuerpo, humano].
nucleo(ciencias_salud) --> [anatomia].

% biología
nucleo(biologia) --> [biologia].
nucleo(biologia) --> [seres, vivos].
nucleo(biologia) --> [vida].
nucleo(biologia) --> [organismos].

% lectura
nucleo(lectura) --> [leer].
nucleo(lectura) --> [lectura].
nucleo(lectura) --> [libros].
nucleo(lectura) --> [leer, libros].
nucleo(lectura) --> [literatura].

% debate
nucleo(debate) --> [debatir].
nucleo(debate) --> [debate].
nucleo(debate) --> [debates].
nucleo(debate) --> [discutir].
nucleo(debate) --> [argumentar].
nucleo(debate) --> [discutir, ideas].

% justicia
nucleo(justicia) --> [justicia].
nucleo(justicia) --> [leyes].
nucleo(justicia) --> [ley].
nucleo(justicia) --> [derecho].
nucleo(justicia) --> [legal].

% dibujo
nucleo(dibujo) --> [dibujar].
nucleo(dibujo) --> [dibujo].
nucleo(dibujo) --> [ilustrar].
nucleo(dibujo) --> [disenar].
nucleo(dibujo) --> [diseno].

% creatividad
nucleo(creatividad) --> [creatividad].
nucleo(creatividad) --> [creativo].
nucleo(creatividad) --> [creativa].
nucleo(creatividad) --> [crear].
nucleo(creatividad) --> [imaginar].
nucleo(creatividad) --> [imaginar, cosas].
nucleo(creatividad) --> [una, persona, creativa].
nucleo(creatividad) --> [una, persona, creativo].
nucleo(creatividad) --> [persona, creativa].
nucleo(creatividad) --> [persona, creativo].
nucleo(creatividad) --> [ideas].

% liderazgo
nucleo(liderazgo) --> [liderar].
nucleo(liderazgo) --> [liderazgo].
nucleo(liderazgo) --> [dirigir].
nucleo(liderazgo) --> [liderar, grupos].
nucleo(liderazgo) --> [liderar, personas].
nucleo(liderazgo) --> [guiar].
nucleo(liderazgo) --> [grupos].

% finanzas
nucleo(finanzas) --> [finanzas].
nucleo(finanzas) --> [dinero].
nucleo(finanzas) --> [economia].
nucleo(finanzas) --> [invertir].
nucleo(finanzas) --> [negocios].
nucleo(finanzas) --> [inversiones].

% organización
nucleo(organizacion) --> [organizar].
nucleo(organizacion) --> [organizar, cosas].
nucleo(organizacion) --> [organizar, las, cosas].
nucleo(organizacion) --> [organizacion].
nucleo(organizacion) --> [planificar].
nucleo(organizacion) --> [planear].
nucleo(organizacion) --> [planificacion].
nucleo(organizacion) --> [orden].

% arte
nucleo(arte) --> [arte].
nucleo(arte) --> [artes].
nucleo(arte) --> [pintar].
nucleo(arte) --> [pintura].
nucleo(arte) --> [expresion, artistica].

% naturaleza
nucleo(naturaleza) --> [naturaleza].
nucleo(naturaleza) --> [medio, ambiente].
nucleo(naturaleza) --> [ambiente].
nucleo(naturaleza) --> [animales].
nucleo(naturaleza) --> [plantas].
nucleo(naturaleza) --> [campo].
nucleo(naturaleza) --> [ecologia].

% investigación (sustantivo)
nucleo(investigacion) --> [investigacion].
nucleo(investigacion) --> [investigaciones].

% investigar (verbo)
nucleo(investigar) --> [investigar].
nucleo(investigar) --> [investigo].
nucleo(investigar) --> [explorar].
nucleo(investigar) --> [descubrir].
nucleo(investigar) --> [indagar].

% ciencias
nucleo(ciencias) --> [ciencias].
nucleo(ciencias) --> [ciencia].
nucleo(ciencias) --> [cientifico].
nucleo(ciencias) --> [cientifica].

% escribir
nucleo(escribir) --> [escribir].
nucleo(escribir) --> [redactar].
nucleo(escribir) --> [escribir, textos].
nucleo(escribir) --> [escribir, historias].
nucleo(escribir) --> [textos].

% comunicación
nucleo(comunicacion) --> [comunicacion].
nucleo(comunicacion) --> [comunicar].
nucleo(comunicacion) --> [comunicarme].
nucleo(comunicacion) --> [hablar, en, publico].
nucleo(comunicacion) --> [expresarme].
nucleo(comunicacion) --> [expresar, ideas].
nucleo(comunicacion) --> [hablar].

% deportes
nucleo(deportes) --> [deportes].
nucleo(deportes) --> [deporte].
nucleo(deportes) --> [futbol].
nucleo(deportes) --> [atletismo].
nucleo(deportes) --> [ejercicio].
nucleo(deportes) --> [hacer, ejercicio].
nucleo(deportes) --> [gimnasio].

% enseñanza
nucleo(ensenanza) --> [ensenar].
nucleo(ensenanza) --> [ensenanza].
nucleo(ensenanza) --> [educar].
nucleo(ensenanza) --> [dar, clases].
nucleo(ensenanza) --> [transmitir, conocimientos].
nucleo(ensenanza) --> [explicar].

% movimiento
nucleo(movimiento) --> [movimiento].
nucleo(movimiento) --> [moverme].
nucleo(movimiento) --> [actividad, fisica].
nucleo(movimiento) --> [estar, activo].
nucleo(movimiento) --> [estar, en, movimiento].
nucleo(movimiento) --> [correr].
nucleo(movimiento) --> [caminar].


% -------------------------------------------------------------
% Tokenizador: minúsculas, sin acentos y sin puntuación
% -------------------------------------------------------------

tokenizar(Texto, Tokens) :-
    string_lower(Texto, Minusculas),
    string_chars(Minusculas, Chars),
    maplist(sin_acento, Chars, Limpios),
    recoger(Limpios, Tokens).

sin_acento(C, S) :- tabla(C, S), !.
sin_acento(C, C).

tabla('á', 'a').  tabla('é', 'e').  tabla('í', 'i').
tabla('ó', 'o').  tabla('ú', 'u').  tabla('ü', 'u').
tabla('ñ', 'n').  tabla('à', 'a').  tabla('è', 'e').
tabla('ì', 'i').  tabla('ò', 'o').  tabla('ù', 'u').
tabla('â', 'a').  tabla('ê', 'e').  tabla('î', 'i').
tabla('ô', 'o').  tabla('û', 'u').  tabla('ä', 'a').
tabla('ë', 'e').  tabla('ï', 'i').  tabla('ö', 'o').
tabla('ü', 'u').

recoger([], []).
recoger([C|Cs], Tokens) :-
    ( letra(C) ->
        palabra([C|Cs], Palabra, Resto),
        atom_codes(A, Palabra),
        Tokens = [A|T],
        recoger(Resto, T)
    ;
        recoger(Cs, Tokens)
    ).

palabra([C|Cs], [C|P], Resto) :-
    letra(C),
    !,
    palabra(Cs, P, Resto).
palabra(Resto, [], Resto).

letra(C) :- C @>= 'a', C @=< 'z'.


% -------------------------------------------------------------
% Prueba rápida de la gramática (no la usa Logic.pl).
% Ejecutar con:  ?- probar_gramatica.
% -------------------------------------------------------------
probar_gramatica :-
    ejemplos(Ejemplos),
    forall(member(Frase, Ejemplos),
           ( ( interpretar(Frase, Prefs) ->
                 format('OK   ~w -> ~w~n', [Frase, Prefs])
             ;
                 format('FALLA ~w~n', [Frase])
             )
           )).

ejemplos([
    'Me gustan las matemáticas',
    'Disfruto trabajar con tecnología',
    'Me gusta resolver problemas',
    'No me gusta la tecnología',
    'Me interesa ayudar a las personas',
    'Prefiero escuchar a los demás',
    'Me gusta leer y dibujar',
    'Me gustan las matemáticas y la tecnología',
    'Odio leer',
    'Me considero una persona creativa',
    'La ventana está abierta'
]).
