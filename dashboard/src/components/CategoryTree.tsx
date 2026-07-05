"use client";

import Link from "next/link";
import type { CategoryTreeNode } from "@/lib/contract-types";

export function CategoryTree({ nodes, depth = 0 }: { nodes: CategoryTreeNode[]; depth?: number }) {
  return (
    <ul className={depth === 0 ? "space-y-1" : "ml-5 mt-1 space-y-1 border-l border-slate-200 pl-3"}>
      {nodes.map((node) => (
        <li key={node.id}>
          <Link
            href={`/catalog/${node.id}`}
            className="flex items-center gap-2 rounded px-2 py-1 text-sm hover:bg-slate-100"
          >
            <span>{node.name}</span>
            <span className="text-xs text-slate-400">/{node.slug}</span>
            {node.isLeaf && <span className="rounded bg-blue-100 px-1.5 py-0.5 text-[10px] font-medium text-blue-700">leaf</span>}
          </Link>
          {node.children.length > 0 && <CategoryTree nodes={node.children} depth={depth + 1} />}
        </li>
      ))}
    </ul>
  );
}
