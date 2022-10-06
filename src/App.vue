<template>
  <div id="app">
    <h1>Morra Game</h1>

    <h5>Choose a role:</h5>
    <button class="mt-2" @click="alice()">Alice</button> 
    <button class="mt-2 ml-4" @click="bob()">Bob</button>
    <h3 class="mt-4">{{role}}</h3>

    <div class="mt-4" v-if="role == 'Alice'">
      <button @click="createContract()">Click to Deploy Contract</button>
      <p class="mt-2">Contract Address (COPY):</p>
      <h4>{{ ctcInfoStr }}</h4>
    </div>

    <div class="mt-4" v-else-if="role== 'Bob'">
      <div class="m-4">
        <b-form-input sm v-model="ctcStr" placeholder="PASTE the contract created by Alice here"></b-form-input>
        <button class="mt-2" @click="attachContract()">Attach Contract</button>
      </div>


      <div v-if="wager > 0">
        Do you want to accept wager of {{ wager }} ?
        <button class="mt-2" @click="yesnoWager(true)">YES</button>
        <button class="mt-2 ml-4" @click="yesnoWager(false)">NO</button>
      </div>
    </div>

    <div v-if="displayHandsState">
      <h4>Last result are :</h4>
      <p> Alice hand: {{ aliceHands }} | Alice guess: {{ aliceGuess }} </p>
      <p> Bob hand: {{ bobHands }} | Bob guess: {{ bobGuess }}</p>
    </div>

    <div v-if="getHandState">
      Play your hand :
      <button v-for="(x, index) in 6" :key="x" :index="index" @click="readHand(0)">{{index}}</button>
    </div>

    <div v-if="getGuessState">
      Shout your total guess:
      <button v-for="(x, index) in 11" :key="x" :index="index" @click="readGuess(index)">{{index}}</button>
    </div>

    <div v-if="displayResultState">
      <h5>{{ result }}</h5>
    </div>


    <p> Contract Address: {{ address }} </p>
    <p> Balance (atomic form): {{ balAtomic}} ALGO</p>
    <p> Balance: {{ bal }} ALGO</p> 

    <button @click="updateBalance()">Update your Balance</button>
  </div>
</template>

<script>
import * as backend from "../build/index.main.mjs";
import { loadStdlib } from "@reach-sh/stdlib";

const stdlib = loadStdlib("ALGO");
stdlib.setProviderByName("TestNet");

// console.log(stdlib);

const toSU = (au) => stdlib.formatCurrency(au, 4);

var commonInteract = {};
var aliceInteract = {};
var bobInteract = {};

const OUTCOME = ["NULL", "Alice Wins", "Bob Wins"];

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
      ctc: "",
      ctcInfoStr: "",
      ctcStr: "",
      handOption: [],

      contractCreated: false,
      displayResultState: false,
      displayHandsState: false,
      getGuessState: false,
      getHandState: false,

      wager: 0,
      hand: "",
      guess: "",
      aliceHands: "",
      aliceGuess: "",
      bobHands: "",
      bobGuess: "",
      result: "",
      acceptWager: false,
    };
  },
  methods: {
    allFunc() {
      commonInteract = {
        ...stdlib.hasRandom,

        reportResult: async (result) => {
          this.reportResult(result);
        },

        reportHand: async (alice, aliceGuess, bob, bobGuess) => {
          this.reportHand(alice, aliceGuess, bob, bobGuess);
        },

        informTimeout: () => {
          this.informTimeout();
        },

        getFingerCount: async () => {
          this.getFingerCountState = true;
          await this.waitUntil(() => this.hand !== "");
          console.log(this.hand);
          const hand = stdlib.parseCurrency(this.hand);
          this.hand = "";
          this.getFingerCountState = false;
          return hand;
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

    async reportResult(result) {
      this.result = OUTCOME[result];
      
      this.displayResultState = true;
      
      await this.updateBalance();
    },

    reportHand(alice, aliceGuess, bob, bobGuess) {
      this.aliceHands = toSU(alice);
      this.aliceGuess = toSU(aliceGuess);
      this.bobHands = toSU(bob);
      this.bobGuess = toSU(bobGuess);

      this.displayHandsState = true;
    },

    readHand(hand) {
      this.hand = hand;
    },

    readGuess(guess) {
      this.guess = guess;
    },

    async createContract() {
      this.ctc = await this.acc.contract(backend);
      this.ctc.p.Alice(aliceInteract); // refer to index.rsh

      let info = await this.ctc.getInfo();
      this.ctcInfoStr = JSON.stringify(info);

      this.contractCreated = true;
      await this.updateBalance();
    },

    async alice() {
      await this.allFunc();
      aliceInteract = {
        ...commonInteract,
        wager: stdlib.parseCurrency(1),
        deadline: stdlib.parseCurrency(10),
      };
      
      try {
        this.role = "Alice";
        // dont create new acc, use algo wallet
        this.acc = await stdlib.newAccountFromMnemonic(secret1);
        // console.log(this.acc, secret1)

        // this.address = stdlib.formatAddress(this.acc.getAddress());         
        // this.balAtomic = await stdlib.balanceOf(this.acc);
        // this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
      } 
      
      catch (err) {
        console.log(err);
      }
    },

    async yesnoWager(res) {
      this.acceptWager = res;
    },

    async attachContract() {
      this.ctc = await this.acc.contract(backend, JSON.parse(this.ctcStr));
      // console.log("ssss: ", this.ctcStr);
      await this.ctc.p.Bob(bobInteract);
      // console.log("bobsss: ", bobInteract);
      await this.updateBalance();
    },

    async bob() {
      this.allFunc();
      bobInteract = {
        ...commonInteract,
        acceptWager: async (wager) => {
          this.wager = toSU(wager),
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
