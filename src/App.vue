<template>
  <div id="app">
    <h1>Morra Game</h1>

    <div v-if="role ==''">
      <h5>Choose a role:</h5>
      <button class="mt-2" @click="alice()">Alice</button> 
      <button class="mt-2 ml-4" @click="bob()">Bob</button>
    </div>
      
    <h3 class="mt-4">{{role}}</h3>

    <div class="mt-4" v-if="role == 'Alice'">
      <div v-if="deployedContractInfo!=''">
        <h4 class="mt-2">COPY the game contract info</h4>
        <h5>{{ deployedContractInfo }}</h5>
      </div>      
      
      <button v-else class="m-4" @click="createContract()">Click to Deploy Contract</button>

    </div>

    <div class="mt-4" v-else-if="role== 'Bob'">
      <div class="m-4">
        <b-form-input sm v-model="deployedContractInfo" placeholder="PASTE the contract info here"></b-form-input>
        <button class="mt-2" @click="attachContract()">Attach Contract</button>
      </div>


      <div v-if="wager > 0">
        Do you want to accept wager of {{ wager }} ?
        <button class="mt-2" @click="yesnoWager(true)">YES</button>
        <button class="mt-2 ml-4" @click="yesnoWager(false)">NO</button>
      </div>

    </div>

    <hr />
    
    <div v-if="displayFingerState">
      <h5>Outcome: </h5>
      <p> Alice finger: {{ fingerAlice }} | Alice guess: {{ guessAlice }} </p>
      <p> Bob finger: {{ fingerBob }} | Bob guess: {{ guessBob }}</p>
    </div>

    <div v-if="displayResultState">
      <h4>Last result are :</h4><h5>{{ gameOutcome }}</h5>
    </div>

    <div v-if="getFingerState">
      Play your finger :
      <button v-for="(x, index) in 6" :key="x" :index="index" @click="readFinger(index)">{{index}}</button>
    </div>

    <!-- {{getFingerState}}
    {{gameOutcome}} -->

    <div v-if="getGuessState">
      Shout your total guess:
      <button v-for="(x, index) in 11" :key="x" :index="index" @click="readGuess(index)">{{index}}</button>
    </div>

    <hr />

    <div v-if="role !=''">
      <p> {{role}}'s Contract Address: {{ address }} </p>
      <p> Balance (atomic form): {{ balAtomic}} ALGO</p>
      <p> Balance: {{ bal }} ALGO</p> 


      <button @click="updateBalance()">Update your Balance</button>
    </div>
  </div>
</template>

<script>
import * as backend from "../build/index.main.mjs";
import { loadStdlib } from "@reach-sh/stdlib";

const stdlib = loadStdlib("ALGO");

stdlib.setProviderByName("TestNet");

// console.log(stdlib);

const toStandardUnit = (au) => stdlib.formatCurrency(au, 4);

var commonInteract = {};
var aliceInteract = {};
var bobInteract = {};

const secret1 = process.env.VUE_APP_SECRET_1;
const secret2 = process.env.VUE_APP_SECRET_2;

export default {
  data: () => {
    return {
      role: "",
      acc: "",
      address: "",
      balAtomic: 0,
      bal: 0,
      
      deployedContractInfo: "",
      morraContract: "",

      contractCreated: false,
      displayResultState: false,
      displayFingerState: false,
      getGuessState: false,
      getFingerState: false,

      outcomeOpt: ["NULL", "Alice Wins", "Bob Wins"],

      wager: 0,
      finger: "",
      guess: "",
      fingerAlice: "",
      guessAlice: "",
      fingerBob: "",
      guessBob: "",
      gameOutcome: "",
      acceptWager: false,
    };
  },
  methods: {
    allFunc() {
      commonInteract = {
        ...stdlib.hasRandom,

        reportOutcome: async (result) => {
          this.reportOutcome(result);
          console.log("res from all func: ", result)

        },

        reportFinger: async (alice, guessAlice, bob, guessBob) => {
          this.reportFinger(alice, guessAlice, bob, guessBob);
        },

        informTimeout: () => {
          this.informTimeout();
        },

        getFingerCount: async () => {
          this.getFingerState = true;
          await this.waitUntil(() => this.finger !== "");
          console.log(this.finger);
          
          let fingerCount = stdlib.parseCurrency(this.finger);
          this.finger = "";
          this.getFingerState = false;
          
          return fingerCount;
        },

        getGuess: async () => {
          this.getGuessState = true;
          await this.waitUntil(() => this.guess !== "");
          let guess = stdlib.parseCurrency(this.guess);
          this.guess = "";
          this.getGuessState = false;
          
          return guess;
        },
      };
    },

    async reportOutcome(x) {
      this.gameOutcome = this.outcomeOpt[x]; //x= index
      console.log(x)
      this.displayResultState = true;
      await this.updateBalance();
    },

    reportFinger(alice, guessAlice, bob, guessBob) {
      this.fingerAlice = toStandardUnit(alice);
      this.guessAlice = toStandardUnit(guessAlice);
      this.fingerBob = toStandardUnit(bob);
      this.guessBob = toStandardUnit(guessBob);

      this.displayFingerState = true;
    },

    readFinger(x) {
      this.finger = x;
    },

    readGuess(x) {
      this.guess = x;
    },

    async createContract() {
      this.morraContract = await this.acc.contract(backend);
      console.log(this.morraContract)
      console.log(this.morraContract.p)

      this.morraContract.p.Alice(aliceInteract); // refer to index.rsh

      // this.morraContract = await this.morraContract.getContractAddress();
      this.deployedContractInfo = JSON.stringify( await this.morraContract.getInfo());

      if (this.morraContract!= ''){
        this.contractCreated = true;
        await this.updateBalance();
        console.log("done created contract")
      }

    },

    async alice() {
      await this.allFunc();

      aliceInteract = {
        ...commonInteract,
        wager: stdlib.parseCurrency(1), // offer 1 algo as wager
        deadline: stdlib.parseCurrency(10),
      };
      
      try {
        this.role = "Alice";
        // dont create new acc, use algo wallet
        this.acc = await stdlib.newAccountFromMnemonic(secret1);
        // console.log(this.acc, secret1)

        this.address = stdlib.formatAddress(this.acc.getAddress()); 
        // console.log(this.address) 

        this.balAtomic = await stdlib.balanceOf(this.acc);
        // console.log('sdssd', this.balAtomic) 

        this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));

      } 
      
      catch (err) {
        console.log(err);
      }
    },

    async yesnoWager(x) {
      this.acceptWager = x;
    },

    async attachContract() {      
      this.morraContract = await this.acc.contract(backend, JSON.parse(this.deployedContractInfo));
      await this.morraContract.p.Bob(bobInteract);
      // console.log("bobsss: ", bobInteract);
      await this.updateBalance();
    },

    async bob() {
      this.allFunc();
      bobInteract = {
        ...commonInteract,
        acceptWager: async (wager) => {
          this.wager = toStandardUnit(wager),
          this.waitUntil(() => this.acceptWager == true);
          if (this.acceptWager == false) {
            process.exit(0);
          }
        },
      };

      try {
        this.role = "Bob";
        this.acc = await stdlib.newAccountFromMnemonic(secret2);
        this.address = stdlib.formatAddress(this.acc.getAddress());
        this.balAtomic = await stdlib.balanceOf(this.acc);
        this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
      } catch (err) {
        console.log(err);
      }
    },

    // Common function for all Vue Rech
    waitUntil(condition) {
      return new Promise((resolve) => {
        let interval = setInterval(() => {
          if (!condition()) {
            return;
          }

          clearInterval(interval);
          resolve();
        }, 100);
      });
    },

    async updateBalance() {
      try {
        // console.log("cur bal: ", this.balAtomic, " ", this.bal)
        this.balAtomic = await stdlib.balanceOf(this.acc);
        this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
      } catch (err) {
        console.log(err);
      }
    },
  },
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
