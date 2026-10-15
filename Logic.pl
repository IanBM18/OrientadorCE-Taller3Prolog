:- encoding(utf8).

% =============================================================
% Logic.pl - Reglas de recomendacion y control de la interaccion
% OrientadorCE - Taller 3 Prolog (CE1106)
%
% Para correr el programa:
%   ?- consult('Logic.pl').
%   ?- iniciar.
%
% Este archivo carga BD.pl (hechos) y BNF.pl (gramatica).
% De BNF.pl se usa interpretar(+Texto, -Prefs), donde Prefs es una
% lista con elementos gusta(Interes) o no_gusta(Interes). Si la frase
% no se reconoce, interpretar/2 falla.
% =============================================================

:- ensure_loaded('BD.pl').
:- ensure_loaded('BNF.pl').

% Preferencias que se van guardando durante la conversacion
:- dynamic gusta/1.
:- dynamic no_gusta/1.
:- dynamic preguntado/1.
:- dynamic sin_entrada/0.

% maximo de preguntas despues de la pregunta inicial
max_preguntas(8).

% minimo de afinidades que tienen que coincidir para recomendar
min_coincidencias(2).


% -------------------------------------------------------------
% Inicio de la conversacion
% -------------------------------------------------------------

iniciar :-
    limpiar,
    nl,
    decir('Hola. Estoy aquí para ayudarte a explorar opciones profesionales. ¿Qué te gusta?'),
    leer_preferencia,
    max_preguntas(Max),
    conversar(Max),
    recomendar.

% borra lo que haya quedado de una ejecucion anterior
limpiar :-
    retractall(gusta(_)),
    retractall(no_gusta(_)),
    retractall(preguntado(_)),
    retractall(sin_entrada).

decir(Texto) :-
    format('OrientadorCE: ~w~n', [Texto]).


% -------------------------------------------------------------
% Ciclo de preguntas
% Se detiene cuando ya hay una profesion con todas sus afinidades,
% cuando se acaban las preguntas o cuando no queda nada que preguntar.
% -------------------------------------------------------------

conversar(_) :-
    sin_entrada, !.
conversar(_) :-
    perfil_completo(_), !.
conversar(0) :- !.
conversar(N) :-
    siguiente_interes(Interes), !,
    assertz(preguntado(Interes)),
    texto_pregunta(Interes, Pregunta),
    decir(Pregunta),
    leer_preferencia,
    N1 is N - 1,
    conversar(N1).
conversar(_).

% Lee una linea y la manda a la gramatica. Si no se entiende
% se pide reformular y NO se guarda nada.
leer_preferencia :-
    format('Usuario: '),
    flush_output,
    read_line_to_string(user_input, Linea),
    procesar_linea(Linea).

procesar_linea(end_of_file) :- !,
    assertz(sin_entrada),
    nl, decir('No recibí más respuestas.').
procesar_linea(Linea) :-
    interpretar(Linea, Prefs),
    Prefs \= [], !,
    registrar_todas(Prefs).
procesar_linea(_) :-
    decir('No entendí tu respuesta. ¿Podrías decirlo de otra forma? Por ejemplo: "Me gusta la tecnología" o "No me gusta leer".'),
    leer_preferencia.


% -------------------------------------------------------------
% Registro de preferencias
% Si el usuario cambia de opinion se queda la ultima respuesta.
% -------------------------------------------------------------

registrar_todas([]).
registrar_todas([P|Resto]) :-
    registrar(P),
    registrar_todas(Resto).

registrar(gusta(I)) :- !,
    retractall(no_gusta(I)),
    ( gusta(I) -> true ; assertz(gusta(I)) ),
    marcar_preguntado(I).
registrar(no_gusta(I)) :- !,
    retractall(gusta(I)),
    ( no_gusta(I) -> true ; assertz(no_gusta(I)) ),
    marcar_preguntado(I).
registrar(_).

marcar_preguntado(I) :- preguntado(I), !.
marcar_preguntado(I) :- assertz(preguntado(I)).


% -------------------------------------------------------------
% Reglas de recomendacion
% -------------------------------------------------------------

% Una profesion se descarta si al usuario no le gusta alguna de sus
% afinidades, o si dijo que le gusta algo que esta en sus incompatibles.
descartada(P) :-
    afinidades(P, Afinidades),
    member(I, Afinidades),
    no_gusta(I), !.
descartada(P) :-
    incompatibles(P, Lista),
    member(I, Lista),
    gusta(I), !.

% Cantidad de afinidades de la profesion que le gustan al usuario
coincidencias(P, N) :-
    afinidades(P, Afinidades),
    include(gusta, Afinidades, Comunes),
    length(Comunes, N).

% Profesion que no contradice ninguna preferencia y tiene suficientes coincidencias
compatible(P, N) :-
    profesion(P),
    \+ descartada(P),
    coincidencias(P, N),
    min_coincidencias(Min),
    N >= Min.

% Todas las afinidades de la profesion ya fueron confirmadas
perfil_completo(P) :-
    profesion(P),
    \+ descartada(P),
    afinidades(P, Afinidades),
    forall(member(I, Afinidades), gusta(I)).

% Se recomiendan las compatibles con mas coincidencias (puede haber empate)
mejores_opciones(Mejores) :-
    findall(N-P, compatible(P, N), Pares),
    Pares \= [],
    max_member(Max-_, Pares),
    findall(P, member(Max-P, Pares), Mejores).


% -------------------------------------------------------------
% Eleccion de la siguiente pregunta
% Se pregunta por una afinidad de la profesion que va mejor
% (la que tiene mas coincidencias y no esta descartada).
% Si ninguna tiene coincidencias se recorre en el orden de BD.pl
% -------------------------------------------------------------

siguiente_interes(I) :-
    findall(N-P, ( profesion(P), \+ descartada(P), coincidencias(P, N) ), Pares),
    ordenar_desc(Pares, Ordenados),
    member(_-P, Ordenados),
    afinidades(P, Afinidades),
    member(I, Afinidades),
    \+ preguntado(I), !.

% de mayor a menor coincidencias; sort/4 con @>= no quita repetidos
% y respeta el orden de BD.pl cuando hay empate
ordenar_desc(Pares, Ordenados) :-
    sort(1, @>=, Pares, Ordenados).


% -------------------------------------------------------------
% Resultado final
% -------------------------------------------------------------

recomendar :-
    mejores_opciones([P]), !,
    nombre(P, Nombre),
    format('OrientadorCE: Según tus preferencias, te recomiendo ~w.~n', [Nombre]),
    explicar(P).
recomendar :-
    mejores_opciones(Lista), !,
    maplist(nombre, Lista, Nombres),
    atomic_list_concat(Nombres, ', ', Texto),
    format('OrientadorCE: Según tus preferencias, hay varias opciones que te pueden servir: ~w.~n', [Texto]).
recomendar :-
    decir('Lo siento, con las preferencias que me diste no encontré una profesión compatible en mi base de conocimientos.'),
    mostrar_negativas.

% Muestra con que gustos coincidio la profesion
explicar(P) :-
    afinidades(P, Afinidades),
    include(gusta, Afinidades, Comunes),
    maplist(texto_interes, Comunes, Textos),
    atomic_list_concat(Textos, ', ', T),
    format('OrientadorCE: Coincide con lo que te gusta: ~w.~n', [T]).

mostrar_negativas :-
    findall(T, ( no_gusta(I), texto_interes(I, T) ), Lista),
    Lista \= [], !,
    atomic_list_concat(Lista, ', ', Texto),
    format('OrientadorCE: Descarté las profesiones relacionadas con: ~w.~n', [Texto]).
mostrar_negativas.


% -------------------------------------------------------------
% Textos para mostrar en consola
% -------------------------------------------------------------

nombre(ingenieria_computadores, 'Ingeniería en Computadores').
nombre(psicologia, 'Psicología').
nombre(medicina, 'Medicina').
nombre(derecho, 'Derecho').
nombre(arquitectura, 'Arquitectura').
nombre(administracion, 'Administración').
nombre(diseno_grafico, 'Diseño Gráfico').
nombre(biologia, 'Biología').
nombre(periodismo, 'Periodismo').
nombre(educacion_fisica, 'Educación Física').

% Pregunta para cada interes de BD.pl
pregunta(matematicas, '¿Te gustan las matemáticas?').
pregunta(tecnologia, '¿Te gusta la tecnología?').
pregunta(resolver_problemas, '¿Te gusta resolver problemas?').
pregunta(ayudar_personas, '¿Te interesa ayudar a las personas?').
pregunta(escuchar, '¿Prefieres escuchar o hablar?').
pregunta(empatia, '¿Te consideras una persona empática?').
pregunta(ciencias_salud, '¿Te interesan las ciencias de la salud?').
pregunta(biologia, '¿Te gusta la biología?').
pregunta(lectura, '¿Te gusta leer?').
pregunta(debate, '¿Te gusta debatir?').
pregunta(justicia, '¿Te interesa la justicia?').
pregunta(dibujo, '¿Te gusta dibujar?').
pregunta(creatividad, '¿Te consideras una persona creativa?').
pregunta(liderazgo, '¿Te gusta liderar grupos?').
pregunta(finanzas, '¿Te interesan las finanzas?').
pregunta(organizacion, '¿Te gusta organizar las cosas?').
pregunta(arte, '¿Te gusta el arte?').
pregunta(naturaleza, '¿Te gusta la naturaleza?').
pregunta(investigacion, '¿Te gusta la investigación?').
pregunta(ciencias, '¿Te gustan las ciencias?').
pregunta(escribir, '¿Te gusta escribir?').
pregunta(investigar, '¿Te gusta investigar?').
pregunta(comunicacion, '¿Te interesa la comunicación?').
pregunta(deportes, '¿Te gustan los deportes?').
pregunta(ensenanza, '¿Te gusta enseñar?').
pregunta(movimiento, '¿Te gusta estar en movimiento?').

% si falta alguna pregunta se arma una generica
texto_pregunta(I, T) :- pregunta(I, T), !.
texto_pregunta(I, T) :-
    texto_interes(I, Texto),
    format(atom(T), '¿Te interesa ~w?', [Texto]).

% convierte el atomo en texto legible (resolver_problemas -> resolver problemas)
texto_interes(I, T) :-
    atomic_list_concat(Partes, '_', I),
    atomic_list_concat(Partes, ' ', T).
