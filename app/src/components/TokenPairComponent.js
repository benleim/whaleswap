import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import logo from "./../logo.png";

const { AccountData, ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => {
  // destructure drizzle and drizzleState from props
  return (
    <div className="App">
      <div>
        <img src={logo} alt="drizzle-logo" />
        <h1>Pennswap</h1>
        <p>
          Welcome to the danger zone.
        </p>
      </div>

      <div className="section">
        <h2>Active Account</h2>
        <AccountData
          drizzle={drizzle}
          drizzleState={drizzleState}
          accountIndex={0}
          units="ether"
          precision={3}
        />
      </div>

      <div className="section">
        <h3>Total Pairs:</h3>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="Factory"
            method="allPairsLength"
        />

        <h3>Add Pair</h3>
        <ContractForm
          drizzle={drizzle}
          contract="Factory"
          method="createPair"
          labels={["Token1 Address", "Token2 Address"]}
          sendArgs={{gas: 6000000, gasPrice: 40000000000}}
        />
      </div>

    </div>
  );
};
