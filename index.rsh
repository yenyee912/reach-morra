'reach 0.1';

// create enum for results
const [ isResult, NO_WINS, A_WINS, B_WINS, DRAW,  ] = makeEnum(4);

// 0 = none, 1 = B wins, 2 = draw , 3 = A wins
const winner = (handAlice, guessAlice, handBob, guessBob) => {
  const total = handAlice + handBob;

  if ( guessAlice == total && guessBob == total  ) 
    return DRAW
  else if ( guessAlice == total )
    return A_WINS  
  else if ( guessBob == total) 
    return B_WINS
  else
    return NO_WINS
 
}
  
assert(winner(1,2,1,3 ) == A_WINS);
assert(winner(5,10,5,8 ) == A_WINS);

assert(winner(3,6,4,7 ) == B_WINS);
assert(winner(1,5,3,4 ) == B_WINS);

assert(winner(0,0,0,0 ) == DRAW);
assert(winner(2,4,2,4 ) == DRAW);
assert(winner(5,10,5,10 ) == DRAW);

assert(winner(3,6,2,4 ) == NO_WINS);
assert(winner(0,3,1,5 ) == NO_WINS);

forall(UInt, handAlice =>
  forall(UInt, handBob =>
    forall(UInt, guessAlice =>
      forall(UInt, guessBob =>
    assert(isResult(winner(handAlice, guessAlice, handBob , guessBob)))
))));


const commonInteract = {
  ...hasRandom,
  reportResult: Fun([UInt], Null),
  reportHand: Fun([UInt, UInt, UInt, UInt], Null),
  informTimeout: Fun([], Null),
  getFingerCount: Fun([], UInt),
  getGuess: Fun([], UInt),
};

const aliceInterect = {
  ...commonInteract,
  wager: UInt, 
  deadline: UInt, 
}

const bobInteract = {
  ...commonInteract,
  acceptWager: Fun([UInt], Null),
}


export const main = Reach.App(() => {
  const Alice = Participant('Alice',aliceInterect );
  const Bob = Participant('Bob', bobInteract );
  init();

  // Check for timeouts
  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline)
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager);
  });
  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
  

  var result = DRAW;
   invariant( balance() == 2 * wager && isResult(result) );

   while ( result == DRAW || result == NO_WINS ) {
    commit();

  Alice.only(() => {
    const _handAlice = interact.getFingerCount();
    const [_commitAlice1, _saltAlice1] = makeCommitment(interact, _handAlice);
    const commitAlice1 = declassify(_commitAlice1);

    const _guessAlice = interact.getGuess();
    const [_commitAlice2, _saltAlice2] = makeCommitment(interact, _guessAlice);
    const commitAlice2 = declassify(_commitAlice2);

  })
  

  Alice.publish(commitAlice1, commitAlice2)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
    commit();

  unknowable(Bob, Alice(_handAlice,_guessAlice, _saltAlice1,_saltAlice2 ));
  
  Bob.only(() => {
    const handBob = declassify(interact.getFingerCount());
    const guessBob = declassify(interact.getGuess());
  });

  Bob.publish(handBob, guessBob)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
  commit();

  Alice.only(() => {
    const saltAlice1 = declassify(_saltAlice1);
    const handAlice = declassify(_handAlice);
    const saltAlice2 = declassify(_saltAlice2);
    const guessAlice = declassify(_guessAlice);

  });

  Alice.publish(saltAlice1,saltAlice2, handAlice, guessAlice)
    .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
  checkCommitment(commitAlice1, saltAlice1, handAlice);
  checkCommitment(commitAlice2, saltAlice2, guessAlice);

  // Report results to all participants
  each([Alice, Bob], () => {
    interact.reportHand(handAlice, guessAlice, handBob, guessBob);
  });

  result = winner(handAlice, guessAlice, handBob, guessBob);
  continue;
}
assert(result == A_WINS || result == B_WINS);

each([Alice, Bob], () => {
  interact.reportResult(result);
});

transfer(2 * wager).to(result == A_WINS ? Alice : Bob);
commit();

});
