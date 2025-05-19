import CreateSCW from "@/components/createSWC";

export default function CreateWalletPage() {
  return (
    <main className="flex flex-col py-6 items-center gap-5">
      <h1 className="text-5x1 font-bold">Create New Wallet</h1>
      <p className="text-gray-400">
        Enter the signer addresses for this account
      </P>
      <CreateSCW />
    </main>
  );
}
