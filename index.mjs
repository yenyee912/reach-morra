import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const suStr = stdlib.standardUnit;
const toAU = (su) => stdlib.parseCurrency(su);
const toSU = (au) => stdlib.formatCurrency(au, 4);
const iBal = toAU(1000);
const showBalance = async (acc) => console.log(`Your balance is ${toSU(await stdlib.balanceOf(acc))} ${suStr}.`);

const OUTCOME = ['NO_WINS', 'Alice WINS', 'Bob WINS', 'DRAW',];

const commonInteract = {
  ...stdlib.hasRandom,
  reportResult: (result) => { console.log(`The result is: ${OUTCOME[result]}`) },

  reportHand: (A, aGuess, B, bGuess) => {
    console.log(`Alice played hand: ${toSU(A)}, guess: ${toSU(aGuess)} `)
    console.log(`Bob played hand: ${toSU(B)}, guess: ${toSU(bGuess)} `)
    console.log(`Total fingers : ${toSU(parseInt(A) + parseInt(B))}`)
  },
  informTimeout: () => {
    process.exit(1);
  },
  getFingerCount: async () => {
    let fingerCount = await ask.ask(`How many fingers?`, stdlib.parseCurrency);
    return fingerCount
  },
  //getGuess: Fun([], UInt),
  getGuess: async () => {
    let guess = await ask.ask(`Guess total fingers?`, stdlib.parseCurrency);
    return guess
  },

}


let isAlice = await ask.ask(`Are you Alice?`, ask.yesno);
let who = isAlice ? 'Alice' : 'Bob';
console.log(`Starting MORRA as ${who}`);
let acc = null;

if (who === 'Alice') {
  let amt = await ask.ask(`Wager amount: `, stdlib.parseCurrency);

  const aliceInteract = {
    ...commonInteract,
    wager: amt,
    deadline: 100,
  }

  // create new test account with 1000 ALGO
  const acc = await stdlib.newTestAccount(iBal);
  await showBalance(acc);

  // First participant, deploy the contract
  const ctc = acc.contract(backend);

  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`);
  });

  await ctc.p.Alice(aliceInteract);
  await showBalance(acc);

} else if (who === 'Bob') {
  const bobInteract = {
    ...commonInteract,
    acceptWager: async (amt) => {
      const isWagerAccept = await ask.ask(`Accept ${toSU(amt)} as wager?`, ask.yesno)
      if (!isWagerAccept) 
        process.exit(0);
      
    }
  }

  const acc = await stdlib.newTestAccount(iBal);
  const info = await ask.ask('Paste contract info: ', (s) => JSON.parse(s));

  const ctc = acc.contract(backend, info);
  await showBalance(acc);
  await ctc.p.Bob(bobInteract);
  await showBalance(acc); // rmb to show cur balance again
}

ask.done();
