import Web3 from "web3";
import Factory from "./contracts/Factory.json";

const options = {
  web3: {
    block: false,
    customProvider: new Web3("ws://localhost:8545"),
  },
  contracts: [Factory],
  events: {
    
  },
};

export default options;
