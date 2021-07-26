import {ethers} from "hardhat"
import { Contract, BigNumber } from 'ethers';
import fs = require('fs')
import path = require('path')
import hasher = require('../contracts/Hasher.json')
import Ethers = require('ethers');

function _dir(d: string) {
    return path.join(__dirname, d)
}

const _dbFile = _dir('../local/deploy-db.json')

function dbSet(k: string, v: string) {
    const b = fs.existsSync(_dbFile)
    let o = b ? JSON.parse(
        fs.readFileSync(_dbFile, 'ascii')
    ) : {}

    o[k] = v
    fs.writeFileSync(_dbFile, JSON.stringify(o))
}

function dbGet(k: string): string {
    const b = fs.existsSync(_dbFile)
    if (!b)
        return ''

    let o = JSON.parse(fs.readFileSync(_dbFile, 'ascii'))
    return o[k]
}

async function deployContract(id: string, name: string, args: any[], libraries: Record<string, string> = {}): Promise<Contract> {
    let addr = dbGet(id)

    if (addr) {
        return (await ethers.getContractFactory(name, {
            libraries: libraries
        })).attach(addr)
    }

    const lib = await ethers.getContractFactory(name, {
        libraries: libraries
    })

    const r = await lib.deploy(...args)
    dbSet(id, r.address)
    return r
}

async function deployContractABI(id: string, abi: string, bytecode: string): Promise<any> {

    //连接网络
    // let url = "http://127.0.0.1:8545";
    let url = "http://192.168.1.28:7010";
    let customHttpProvider = new Ethers.providers.JsonRpcProvider(url);

    // 加载钱包以部署合约
    // let privateKey = '0xe7edd7879262252a4212bee007b80fe3cab68e091bbdbcacb20ee6cc40be5c94';
    let privateKey = '0x1388549e5b0385152f243c45b013f59f8c667b30dacf21b8c84f2ce6215ffa6b';

    let wallet = new Ethers.Wallet(privateKey, customHttpProvider);

    let factory = new Ethers.ContractFactory(hasher.abi, hasher.bytecode, wallet);

    let contract = await factory.deploy();

    dbSet(id, contract.address)

    return contract

}

interface tornado {
    Verifier: Contract
    Hasher: Contract
    ETHTornado: Contract
}
let _denomination = BigNumber.from('1000000000000000000')

let _merkleTreeHeight = 20

const _operator = "0x26050D28cAB5424FDCeb0f0F120D64Aee225B7c0"

async function main() {
    let ret: tornado = <any>{}

    ret.Hasher = await deployContractABI('HASHER', JSON.stringify(hasher.abi), hasher.bytecode)

    ret.Verifier = await deployContract('VERIFIER', 'Verifier', [])

    ret.ETHTornado = await deployContract('ETHTORNADO', 'ETHTornado', [ret.Verifier.address, _denomination, _merkleTreeHeight, _operator], {
        Hasher: ret.Hasher.address
    })

    for (let k of Object.keys(ret)) {
        let v: Contract | tornado = (<any>ret)[k]
        console.log(`${k} = ${(<any>v).address}`)
    }
}

main().catch(console.error)

